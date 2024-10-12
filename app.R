library(shiny)
library(bslib)
library(leaflet)
library(tidyverse)
library(plotly)

# setting the custom icons
earthQuakeIcons <- iconList(
  earthquake_high = makeIcon(
    './assets/circle3_red.svg',
    iconWidth = 24,
    iconHeight = 24
  ),
  earthquake_medium = makeIcon(
    './assets/circle3_orange.svg',
    iconWidth = 40,
    iconHeight = 40
  ),
  earthquake_low = makeIcon(
    './assets/circle3_green.svg',
    iconWidth = 40,
    iconHeight = 40
  )
)

# read the cleaned dataset
df_clean <- read.csv('./data/cleaned_data.csv')


# death and damages emdat data
emdat_df <- read.csv('./data/em_dat_public_earthquake.csv')

emdat_df <- emdat_df %>% mutate(across(where(is.character), ~ iconv(.x, from = "", to = "UTF-8", sub = "")))

# extract the year list
year_list <- as.list(unique(emdat_df$Start.Year))

# Convert the date column from DD/MM/YYYY format to Date object
df_clean$Date <- as.Date(df_clean$Date, format = "%d/%m/%Y")

# Split into day, month, and year
df_clean$Day <- as.integer(format(df_clean$Date, "%d"))
df_clean$Month <-  as.integer(format(df_clean$Date, "%m"))
df_clean$Year <-  as.integer(format(df_clean$Date, "%Y"))



#######################
#### GEOSPATIAL
###########################

world_earthquakes <- card(
  card_header("Quake Analyser"),
  
  # adds sidebar output
  layout_sidebar(
    fillable = TRUE,
    
    # slider in sidebar
    sidebar = sidebar(
      
      # slider input to select the year
      sliderInput(
        "year", "Select the year", min = 1965, max = 2016, value = 1965,
        animate = animationOptions(interval = 3000, loop = TRUE)
      ),
      
      verbatimTextOutput("year"),
      
      # select input to select the magnitude
      sliderInput( 
        "mag", "Eartquake Magnitude", 
        min = 0, max = 10, step = 0.1,
        value = c(6,10) 
      ),
      
      verbatimTextOutput("mag")
      
    ),
    # sidebar ends
    
    # plots the leaflet map
    leafletOutput("map")
    # plot ends hear
    
  )
)


##########################
#### Timeseries Analyser
#############################


timeseries_analyser <- card(
  card_header("Earthquakes over the years"),
  
  # adds sidebar output
  layout_sidebar(
    fillable = TRUE,
    
    # slider in sidebar
    sidebar = sidebar(
      
      # select input to select the magnitude
      sliderInput( 
        "mag_2", "Eartquake Magnitude", 
        min = 0, max = 10, step = 0.1,
        value = c(6,10) 
      ),
      
      verbatimTextOutput("mag_2")
      
    ),
    # sidebar ends
    
    # timeseries plot
    plotlyOutput(outputId = "timeseries_plot")
    
  )
)



########################
### HOME
#########################


home <-  card(
    card_header("Global Earthquake Dashboard"),
    
    # sets the card size to full screen
    full_screen = TRUE,
    
    # adds sidebar output
    layout_sidebar(
      fillable = TRUE,
      
      # slider in sidebar
      sidebar = sidebar(
        
        selectInput( 
          "home_year_select", 
          "Select Year:", 
          year_list,
          selected="2023"
        ),
        
        downloadButton("downloadData", "Download CSV")
        
      ),
      # sidebar ends
      
      # value boxes
      layout_column_wrap(
        width = 1/3,
        value_box( 
          title = "Earthquakes", 
          textOutput("earthquakes"), 
          "Total number of significant earthquakes recorded", 
          showcase = icon("bullseye"), 
          theme = "bg-gradient-orange-indigo"
          # full_screen = TRUE 
        ),
        value_box( 
          title = "Magnitude", 
          textOutput("magnitude"), 
          "Highest magnitude recorded", 
          showcase = icon("wave-square"), 
          theme = "bg-gradient-blue-orange"
          # full_screen = TRUE 
        ),
        value_box( 
          title = "Fatalities", 
          textOutput("deaths"), 
          "Total number of deaths due to earthquakes", 
          showcase = icon("heart-pulse"), 
          theme = "bg-gradient-red-indigo"
          # full_screen = TRUE 
        ), 
        value_box( 
          title = "Damages", 
          textOutput("damages"), 
          "Total cost of damages in USD", 
          showcase = icon("coins"), 
          theme = "bg-gradient-yellow-indigo" 
          # showcase_layout = "top", 
          # full_screen = TRUE 
        ), 
        value_box( 
          title = "Injured", 
          textOutput("injuries"), 
          "Total number of people injured", 
          showcase = icon("user-injured"), 
          theme = "bg-gradient-pink-indigo"
          # showcase_layout = "top", 
          # full_screen = TRUE 
        ),
        
        value_box( 
          title = "Homeless", 
          textOutput("homeless"), 
          "Total number of people left homeless", 
          showcase = icon("house-circle-exclamation"), 
          theme = "bg-gradient-teal-indigo"
          # full_screen = TRUE 
        ),
      ),
      # value boxes end here
      card(
        card_header("Most Disastrous Earthquakes"),
        tableOutput("table")
      )
    )
  )





ui <- page_navbar(
    # page title
    title="Earth Quake Analyser",
    
    # sets the page theme
    theme = bs_theme(version = 5, bootswatch = "materia"),
    
    # adds spacer 
    nav_spacer(),
    
    # home page
    nav_panel("Home", home),
    nav_panel("Geospatial Data Visualiser", world_earthquakes),
    nav_panel("Timeseries Analyser", timeseries_analyser),
    nav_panel("Advanced Visualisations", "Page C content")
    
  )



server <- function(input, output) {
  
  # bs_themer()
  
  output$year <- renderPrint({ paste("year:", input$year) })
  
  output$mag <- renderPrint({ paste("magnitude:", input$mag[1], "-", input$mag[2]) })
  
  output$mag_2 <- renderPrint({ paste("magnitude:", input$mag_2[1], "-", input$mag_2[2]) })
  
  output$deaths <- renderText({
    sum(emdat_df %>% filter(Start.Year == input$home_year_select) %>% select(Total.Deaths), na.rm = T)
    })
  output$damages <- renderText({
    paste("US $",
      sum(emdat_df %>% filter(Start.Year == input$home_year_select) %>% select(Total.Damage..Adjusted...000.US..), na.rm = T)
    )
  })
  output$injuries <- renderText({
    sum(emdat_df %>% filter(Start.Year == input$home_year_select) %>% select(No..Injured), na.rm = T)
  })
  output$homeless <- renderText({
    sum(emdat_df %>% filter(Start.Year == input$home_year_select) %>% select(No..Homeless), na.rm = T)
  })
  output$earthquakes <- renderText({
    emdat_df %>%
      filter(Start.Year == input$home_year_select) %>%
      summarise(count = n()) %>%
      pull(count)
  })
  output$magnitude <- renderText({
    emdat_df %>%
      filter(Start.Year == input$home_year_select) %>%
      summarise(magnitude = max(Magnitude, na.rm = T)) %>%
      pull(magnitude)
  })
  
  
  
  # table output
  output$table <- renderTable(
    emdat_df %>%
      filter(Start.Year == input$home_year_select, !is.na(Total.Deaths)) %>%
      select(Country, Location, Magnitude, Total.Deaths, Total.Affected) %>% 
      arrange(desc(Total.Deaths)) %>%
      top_n(3)
    , striped = TRUE)
  
  
  output$downloadData <- downloadHandler(
    filename = "emdat_earthquake_2000_2023.csv",
    content = function(file) {
      write.csv(emdat_df, file)
    }
  )
  
  
  # renders the map output
  output$map <- renderLeaflet({
    
    df_filtered <- df_clean %>%
      filter(
        Year == as.integer(input$year),
        Magnitude >= as.integer(input$mag[1]) & Magnitude <= as.integer(input$mag[2]) 
      )
    
    leaflet(df_filtered %>% filter()) %>%
      addTiles() %>%
      addMarkers(
        lng = ~Longitude, lat = ~Latitude,
        icon = earthQuakeIcons["earthquake_high"],
        clusterOptions = markerClusterOptions(),
        label = ~paste("Date:", Date, "\n", "Magnitude:", Magnitude, "\n", "Depth:", Depth)
      ) %>% 
      setView(138, 25, zoom=3)
  })
  # map ends here
  
  # time series plot
  output$timeseries_plot <- renderPlotly({
    
    # prepares the dataframe and groups data by year
    df <- df_clean %>%
      filter(
        Magnitude >= as.integer(input$mag_2[1]) & Magnitude <= as.integer(input$mag_2[2]) 
      ) %>% 
      filter(!is.na(Year), !is.na(Month)) %>%
      group_by(Year) %>% 
      summarise(count=n())
      
    # plot
    # plots the time series data
    plot_ly(df, type = "scatter", mode="lines") %>% 
      add_trace(x = ~Year, y = ~count) %>% 
      layout(
        title='Time Series plot of EarthQuakes from 1965 - 2016',
        showlegend = F,
        xaxis = list(title = "Year", rangeslider = list(visible = T)),
        yaxis = list(title = "Number of Earthquakes")
      ) %>% 
      layout(
        xaxis = list(zerolinecolor = '#ffff',
                     zerolinewidth = 2,
                     gridcolor = 'ffff'),
        yaxis = list(zerolinecolor = '#ffff',
                     zerolinewidth = 2,
                     gridcolor = 'ffff'),
        plot_bgcolor='#e5ecf6'
        )
    
  })
  # time series plot ends here
  
}


# bootstraps the app
shinyApp(ui, server)
