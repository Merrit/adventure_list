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

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.example_layout).apply {

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

                val listNamesJson = widgetData.getString("listNames", null)
                val listNames = jsonToList(listNamesJson)

                var tasksListString = ""
                for (i in 0 until tasksList.size) {
                    val task: Map<String, Any> = tasksList[i]
                    tasksListString += "\n${task["title"]}"
                }


                // Prepare view. -------------------------------------------------------------------

                // Tapping AppWidget opens app, asking to open that list.
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("launchWidgetList"))
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)


                // Tapping list name opens app, asking to open that list.
                // TODO: If title == "Select List", launch list selection instead.
                setTextViewText(
                    R.id.widget_title,
                    listTitle ?: "Select List",
                )
                val intentWithListName = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("launchWidgetList"))
                setOnClickPendingIntent(R.id.widget_title, intentWithListName)


                // Tapping configure button launches widget config in main app.
                val configureWidgetIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("configureWidget"))
                setOnClickPendingIntent(R.id.configure_button, configureWidgetIntent)


                // Set the tasks list text.
                // Currently just a TextView with newlines, because ListView et al. are annoying.
                setTextViewText(R.id.tasks_list, tasksListString)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun jsonToList(json: String?): JSONArray {
        if (json == null) return JSONArray()

        return JSONArray(json)
    }

    private val defaultJsonObject: JSONObject = JSONObject()
        .put("id", null)
        .put("items", null)
        .put("title", null)

    /// Parse the TaskList json into a JSONObject.
    ///
    /// If the json is null, return an object with default values.
    private fun stringToJsonObject(jsonString: String?): JSONObject {
        if (jsonString == null) return defaultJsonObject;

        return JSONObject(jsonString)
    }
}