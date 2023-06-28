package codes.merritt.adventurelist

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject


class HomeWidgetExampleProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val views = RemoteViews(context.packageName, R.layout.example_layout)

        for (appWidgetId in appWidgetIds) {

            // Prepare data --------------------------------------------------------------------

            val selectedListRawJson: String? = widgetData.getString(
                "selectedList", null,
            )

            val selectedListData: JSONObject = stringToJsonObject(selectedListRawJson)

            val listTitle: String = if (selectedListData.isNull("title")) {
                "Select List"
            } else {
                selectedListData.getString("title")
            }

            val tasksJsonArray: JSONArray = if (selectedListData.isNull("items")) {
                JSONArray()
            } else {
                selectedListData.getJSONArray("items")
            }

            val tasksList = mutableListOf<Map<String, Any>>()
            for (i in 0 until tasksJsonArray.length()) {
                if (tasksJsonArray.length() == 0) break

                val taskJsonObject = tasksJsonArray[i] as JSONObject
                tasksList.add(
                    mapOf(
                        "title" to taskJsonObject.getString("title"),
                        "completed" to taskJsonObject.getBoolean("completed"),
                    )
                )
            }

            var tasksListString = ""
            for (i in 0 until tasksList.size) {
                val task: Map<String, Any> = tasksList[i]
                tasksListString += "\n• ${task["title"]}"
            }

            // List of Task objects
            //
            // Would be good to migrate to using this with a ListView, but
            // it's a bit of a pain to get working with RemoteViews.
            //
            // Aborted attempts: 3
            val tasks = mutableListOf<Task>()
            for (i in 0 until tasksJsonArray.length()) {
                if (tasksJsonArray.length() == 0) break

                val taskJsonObject = tasksJsonArray[i] as JSONObject
                tasks.add(Task(taskJsonObject))
            }


            // Prepare view. -------------------------------------------------------------------

            // Tapping AppWidget opens app, asking to open that list.
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("launchWidgetList"),
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Tapping list name opens app, asking to open that list.
            // TODO: If title == "Select List", launch list selection instead.
            views.setTextViewText(
                R.id.widget_title,
                listTitle,
            )
            val intentWithListName = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("launchWidgetList"),
            )
            views.setOnClickPendingIntent(R.id.widget_title, intentWithListName)

            // Tapping configure button launches widget config in main app.
            // Disabled for now because it stops working after the first use,
            // issue in home widget repo.
            // val intentWithConfig = HomeWidgetLaunchIntent.getActivity(
            //     context,
            //     MainActivity::class.java,
            //     Uri.parse("launchWidgetConfig"),
            // );
            // views.setOnClickPendingIntent(R.id.widget_config_button, intentWithConfig);

            // Set the tasks list text.
            // Currently just a TextView with newlines, because ListView et al.
            // are annoying.
            views.setTextViewText(R.id.tasks_list, tasksListString)
        }

        // Update all widgets.
        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }

        private val defaultJsonObject: JSONObject = JSONObject()
            .put("id", null)
            .put("items", null)
            .put("title", null)

        /// Parse the TaskList json into a JSONObject.
        ///
        /// If the json is null, return an object with default values.
        private fun stringToJsonObject(jsonString: String?): JSONObject {
            if (jsonString == null) return defaultJsonObject

            return JSONObject(jsonString)
        }
    }

class Task {
    var title: String = ""
    var completed: Boolean = false

    constructor(title: String, completed: Boolean) {
        this.title = title
        this.completed = completed
    }

    constructor(json: JSONObject) {
        title = json.getString("title")
        completed = json.getBoolean("completed")
    }
}
