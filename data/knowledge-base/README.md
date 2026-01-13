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

### Additional Documentation

#### `world-cities-overview.md`
Comprehensive overview of major world cities including:
- Detailed city profiles (Tokyo, Paris, New York, London)
- Regional characteristics
- Urban development trends
- Sustainability and technology initiatives

## Data Attribution

- **Primary Data Source**: [Kaggle](https://www.kaggle.com) - The world's largest data science community
- **Purpose**: Educational and demonstration use in this Bedrock Agent test environment
- **License**: Used for educational/demonstration purposes
- **Processing**: Data is automatically chunked and vectorized for semantic search

## Usage for Knowledge Base

These CSV files are automatically uploaded to S3 and used as source documents for the Bedrock Knowledge Base. The knowledge base will:

1. **Ingest** the CSV documents (automatically processed by Bedrock)
2. **Process** and chunk the content into searchable segments
3. **Create embeddings** using Amazon Titan Text Embeddings
4. **Enable** the Bedrock agent to retrieve relevant information via semantic search

## Content Coverage

The sample data covers:
- **Environmental Data**: Air quality and water pollution metrics for 500+ cities (2021)
- **Economic Data**: Cost of living, rent, and purchasing power indices for 400+ cities (2018)
- **Geographic Information**: City locations, regions, and countries
- **Comparative Data**: Cross-city comparisons for environmental and economic factors

## Deployment

The CSV files are automatically uploaded to S3 during Terraform deployment:
- Terraform uses a `local-exec` provisioner to upload files
- Files are uploaded to the Terraform-managed S3 bucket
- Knowledge base data sources reference these files for ingestion

## Future Expansion

Additional content types that could be added:
- Updated economic and environmental datasets from Kaggle
- Climate and weather patterns
- Transportation and infrastructure data
- Tourism and cultural information
- Real-time city metrics and statistics