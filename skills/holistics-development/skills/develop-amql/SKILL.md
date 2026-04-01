---
name: develop-amql
description: Write and edit AML/AQL code for Holistics models, datasets, dashboards, and metrics. Use this whenever the user wants to create or modify a model, dataset, dashboard page, AQL metric, or any file in an AMQL project.
---

## Instructions
* Use [](../working-in-development/) skill to prepare for the development
* **NEVER** assume any AML/AQL syntax, functions, or references.
* Use Holistics knowledge and tools
  * Refer to [](../../references/) and use `search_docs` to learn about code syntax.
  * Use `fetch_dataset` to learn about the dataset (e.g. all available models and fields within that dataset), in order to make accurate edits.
  * Use `generate_aql` to write AQL (e.g. AQL metrics).
  * Use `generate_viz` to define Viz.
  * Use `list_data_sources`, `list_data_source_schemas`, `read_data_source_schema`, `read_data_source_table_schema` to study the underlying database schema in order to write relevant and accurate modeling codes.
* Pay attention to code diagnostics and fix them if possible.

## Example workflow
1. Read relevant codes
2. If working with a dataset, use `fetch_dataset` to view all semantics of the dataset
3. Refer to [](../../references/) and use `search_docs` to learn the correct syntax
4. To write AQL and Viz, use `generate_aql` and `generate_viz`. For others, research further and write the codes.
5. Make code suggestions for the user

## Creating new datasets
* Make sure to properly create the models first before creating the dataset
* Remember to define relationships

## Working with Model files
* You currently are not able to query Models directly. Instead, look for the Dataset containing that Model and query that Dataset instead.
* Always try to write field definitions in AQL first. Only fall back to writing SQL definitions if AQL is not possible.

## Working with Dashboard (page.aml) files
* Remember to arrange your newly created blocks nicely and trim unnecessary spaces

## References
* See [](../../references/holistics.md) to learn about Holistics and AMQL.
* See [](../../references/data_modeling.md) to learn about Data modeling in Holistics.
* See [](../../references/aml.md) to learn about Holistics AML.

## Related skills
* [](../search-docs/)
* [](../write-aql/)
* [](../visualize-data/)