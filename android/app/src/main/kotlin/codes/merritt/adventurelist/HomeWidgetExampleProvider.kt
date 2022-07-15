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

                // Prepare data.
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


                // ---------------------------------------------------------------------------------

                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Swap Title Text by calling Dart Code in the Background
//                setTextViewText(R.id.widget_title, widgetData.getString("title", null)
//                    ?: "No Title Set")
//                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
//                    context,
//                    Uri.parse("homeWidgetExample://titleClicked")
//                )
//                setOnClickPendingIntent(R.id.widget_title, backgroundIntent)

                // Tapping list name opens app, asking to open that list.

                // TODO: If title == "Select List", launch list selection instead.

                setTextViewText(
                    R.id.widget_title,
                    listTitle ?: "Select List",
                )
                val intentWithListName = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("selectedListId"))
                setOnClickPendingIntent(R.id.widget_title, intentWithListName)

                val listNamesJson = widgetData.getString("listNames", null)
                val listNames = jsonToList(listNamesJson)

                var temp = ""
                for (i in 0 until tasksList.size) {
                    val task: Map<String, Any> = tasksList[i]
                    temp += " ${task["title"]}"
                }

                // Tapping configure button launches widget config in main app.
//                configure_button
//                val jsonObject = JSONObject();
//                jsonObject.put("name", "")
                val configureWidgetIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("configureWidget"))
                setOnClickPendingIntent(R.id.configure_button, configureWidgetIntent)


                setTextViewText(R.id.widget_message, temp
                    ?: "No Message Set")
                // Detect App opened via Click inside Flutter
                val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homeWidgetExample://message?message=$listNamesJson"))
                setOnClickPendingIntent(R.id.widget_message, pendingIntentWithData)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun jsonToList(json: String?): JSONArray {
        if (json == null) return JSONArray()

        val jsonArray = JSONArray(json)
//        val jsonObject = JSONObject(json)
//        val jsonArray = jsonObject.toJSONArray()
        val end = true
        return jsonArray
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