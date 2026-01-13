# Knowledge Base Source Data

This directory contains sample data that can be used to populate a Bedrock Knowledge Base for the city facts agent.

## Files

### CSV Datasets (from Kaggle)

#### `world_cities_air_quality_water_pollution_2021.csv`
**Source**: [Kaggle.com](https://www.kaggle.com)
- **Coverage**: 500+ cities worldwide
- **Data Year**: 2021
- **Metrics**: Air Quality Index, Water Pollution Index
- **Format**: City, Region, Country, AirQuality, WaterPollution
- **Use Case**: Environmental data for city comparisons and sustainability insights

#### `world_cities_cost_of_living_2018.csv`
**Source**: [Kaggle.com](https://www.kaggle.com)
- **Coverage**: 400+ cities worldwide  
- **Data Year**: 2018
- **Metrics**: Cost of Living Index, Rent Index, Groceries Index, Restaurant Price Index, Local Purchasing Power Index
- **Format**: Rank, City, multiple economic indicators
- **Use Case**: Economic data for lifestyle and affordability analysis

### Additional Sample Content

#### `world-cities-overview.md`
Comprehensive overview of major world cities including:
- Detailed city profiles (Tokyo, Paris, New York, London)
- Regional characteristics
- Urban development trends
- Sustainability and technology initiatives

#### `city-facts-database.json`
Structured JSON data containing:
- Detailed city information (population, founding dates, areas)
- Notable facts and landmarks for each city
- Categorization by population, region, and founding period
- Easily parseable format for knowledge base ingestion

#### `travel-guide-excerpts.txt`
Travel guide style content featuring:
- Practical visitor information
- Cultural highlights and must-see attractions
- Transportation and navigation tips
- General travel advice and safety considerations

## Data Attribution

- **Primary Data Source**: [Kaggle](https://www.kaggle.com) - The world's largest data science community
- **Purpose**: Educational and demonstration use in this Bedrock Agent test environment
- **License**: Used for educational/demonstration purposes
- **Processing**: Data is automatically chunked and vectorized for semantic search

## Usage for Knowledge Base

These files can be uploaded to an S3 bucket and used as source documents for a Bedrock Knowledge Base. The knowledge base will:

1. **Ingest** these documents (CSV files are automatically processed)
2. **Process** and chunk the content into searchable segments
3. **Create embeddings** using Amazon Titan Text Embeddings
4. **Enable** the Bedrock agent to retrieve relevant information via semantic search

## Content Coverage

The sample data covers:
- **Environmental Data**: Air quality and water pollution metrics (Kaggle dataset)
- **Economic Data**: Cost of living, rent, and purchasing power indices (Kaggle dataset)
- **Geographic Information**: Locations, areas, populations
- **Historical Context**: Founding dates, historical events
- **Cultural Aspects**: Landmarks, districts, local customs
- **Practical Information**: Transportation, dining, attractions
- **Comparative Data**: Cross-city comparisons and categorizations

## Future Expansion

Additional content types that could be added:
- Updated economic and environmental datasets from Kaggle
- Climate and weather patterns
- Local events and festivals
- Transportation schedules and costs
- Accommodation recommendations
- Language and communication guides