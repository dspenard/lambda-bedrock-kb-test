# Data Directory

This directory contains all data files used by the Bedrock Agent Test Bed project, organized by purpose and usage.

## 📁 Folder Structure

```
data/
├── knowledge-base/          # 🧠 Knowledge Base Source Data
│   ├── world_cities_air_quality_water_pollution_2021.csv
│   ├── world_cities_cost_of_living_2018.csv
│   ├── world-cities-overview.md
│   └── README.md
└── lambda-tests/           # 🧪 Lambda Function Test Payloads
    ├── agent-*.json        # Test payloads for agent-based Lambda
    ├── direct-*.json       # Test payloads for direct model Lambda
    └── README.md
```

## 🧠 Knowledge Base Data

**Location**: `knowledge-base/`

Contains CSV datasets from Kaggle that are automatically uploaded to S3 and ingested into the Bedrock Knowledge Base:

- **Air Quality & Water Pollution** (2021): Environmental metrics for 500+ cities
- **Cost of Living** (2018): Economic indicators for 400+ cities

These files provide the agent with factual data about cities worldwide, enabling it to answer questions about environmental conditions and economic factors.

## 🧪 Test Data

**Location**: `lambda-tests/`

Contains JSON payloads for testing both Lambda functions:

- **Agent Tests**: Test the agent-based Lambda with knowledge base integration
- **Direct Tests**: Test the direct model access Lambda
- **Various Cities**: Different cities to test knowledge base coverage

## 🔄 Data Flow

1. **Knowledge Base Files** → S3 Bucket → Bedrock Knowledge Base → Vector Database
2. **Test Files** → Lambda Functions → Bedrock Models/Agents → Responses

## 📊 Data Sources

- **Primary Source**: [Kaggle.com](https://www.kaggle.com) - World's largest data science community
- **Purpose**: Educational and demonstration use
- **Processing**: Automatic chunking and vectorization for semantic search
- **Attribution**: Properly credited in knowledge base documentation

## 🚀 Usage

**Automatic Deployment:**
```bash
# Knowledge base data is automatically uploaded during deployment
./scripts/deploy-complete.sh

# Test data is used by testing scripts
./scripts/test-lambda.sh both Geneva
```

**Manual Testing:**
```bash
# Use specific test payloads
aws lambda invoke --function-name your-function --payload file://data/lambda-tests/agent-berlin.json response.json
```

## 📝 Adding New Data

**Knowledge Base Data:**
1. Add CSV or text files to `knowledge-base/`
2. Update Terraform configuration to include new files
3. Redeploy to upload and ingest new data

**Test Data:**
1. Add JSON files to `lambda-tests/`
2. Follow existing naming convention: `{type}-{city}.json`
3. Use with testing scripts or manual Lambda invocation

## 🔍 Data Quality

- **Validated**: All CSV files are verified for proper formatting
- **Documented**: Each dataset includes source attribution and usage notes
- **Versioned**: Data files are tracked in version control
- **Tested**: Test payloads cover various scenarios and edge cases