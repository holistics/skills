# Holistics
Holistics is a modern BI platform that aims to enable self-service data access for entire organization.

Holistics let data teams pre-define business metrics and data logic. Based on these predefined logic, business users perform self-service data exploration and build their own visualizations and reports.

Business metrics, data logic, and visualizations are all encoded in **AMQL** - a programming language developed by Holistics. This practice is called **Analytics as-code** and it aims to provide **better reusability, composability, and governance** for the user's BI setup.

AMQL consists of 2 inter-connected components:
* AML (Analytics Modeling Language): a declarative language used to describe the semantic layer: data modeling, business metrics, and visualizations.
  * A dashboard (aka. canvas dashboard or page.aml) contains multiple viz blocks
  * A viz block runs AQL to query a dataset and visualize the result data
  * A dataset contains metrics, data models, and relationships
  * A data model contains dimensions
* AQL (Analytics Querying Language): a declarative language that leverages the semantic layer (defined in AML) to query datasets in a metric-centric style. AQL provides
  * Native functions to perform high-level analytics such as Percent of total, Nested aggregation, Level of details, etc.
  * Reusability and composability for metrics