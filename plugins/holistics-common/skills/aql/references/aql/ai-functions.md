:::warning Platform Availability
AI functions are **only available on Databricks and Snowflake** data platforms. These functions leverage the native AI capabilities provided by these platforms and are not supported on other database systems.
:::

Learn more about using AI functions in [Perform AI Queries](/docs/ai/run-ai-functions) docs.


### ai_complete
```jsx
ai_complete(model, prompt)
```

```jsx title="Examples"
ai_complete('databricks-meta-llama-3-3-70b-instruct', 'What is Apache Spark?') // => "Apache Spark is an open-source unified analytics engine..."
ai_complete('gpt-4', 'Explain data warehousing concepts') // => "Data warehousing is the process of collecting and managing data..."
```

**Description**

Queries an AI model with a text prompt and returns the generated response. This function enables natural language interactions with large language models directly within your queries.

:::info Model Availability and Pricing
The exact models available and their pricing depend on your database platform:
- **Databricks**:
  - databricks-gemma-3-12b
  - databricks-llama-4-maverick
  - databricks-meta-llama-3-3-70b-instruct
  - databricks-meta-llama-3-1-8b-instruct
  - databricks-gte-large-en
- **Snowflake**:
  - llama3.1-8b
  - llama3.1-70b
  - mixtral-8x7b
  - mistral-7b
  - jamba-instruct
  - jamba-1.5-mini

Check your platform's documentation for the most up-to-date model list and pricing information.
:::

**Return type**

Text

---

### ai_similarity
```jsx
ai_similarity(text1, text2)
```

```jsx title="Examples"
ai_similarity('Apache Spark', 'Apache Spark') // => 1.0
ai_similarity('cat', 'dog') // => 0.8
ai_similarity('database', 'spreadsheet') // => 0.6
ai_similarity('apple', 'quantum physics') // => 0.1
```


**Description**

Calculates the semantic similarity between two text strings using embedding-based comparison. Returns a value between 0 and 1, where 1 indicates identical meaning and 0 indicates no semantic similarity.

**Return type**

Number

---

### ai_classify

```jsx
ai_classify(text, category1, category2, ...categories)
```

```jsx title="Examples"
ai_classify('My password is leaked.', 'urgent', 'not urgent') // => 'urgent'
ai_classify('Thank you for your purchase', 'complaint', 'feedback', 'inquiry') // => 'feedback'
ai_classify('When will my order arrive?', 'technical', 'billing', 'shipping', 'general') // => 'shipping'
```

**Description**

Classifies the input text into one of the provided categories using AI. The function analyzes the semantic content of the text and returns the most appropriate category from the list provided.

**Return type**

Text

---

### ai_summarize

```jsx
ai_summarize(content)
```

```jsx title="Examples"
ai_summarize('Long article about climate change impacts on coastal regions...') // => "This article discusses the significant effects of climate change on coastal areas, including rising sea levels, increased storm intensity, and ecosystem disruption."
ai_summarize(product_reviews.review_text) // => "Customers praise the product's durability and ease of use but note concerns about the price point."
```

**Description**

Generates a concise summary of the provided text content using AI. This function is useful for creating executive summaries, condensing long-form content, or providing quick insights from verbose text data.

**Return type**

Text
