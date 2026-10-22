---
title: "Dynamic Content Blocks in Canvas Dashboard"
description: "Learn how to use Dynamic Content Blocks to display data-driven, templated content in your Canvas Dashboards by combining visualization data with HTML/Markdown templates."
sidebar_label: Dynamic Content Blocks
---

:::info Beta
This feature will be available soon in November 2025 (beta). [Contact us](https://www.holistics.io/contact-us/) to get early access and be among the first to try Dynamic Content Blocks.
:::

## Introduction

Dynamic Content Blocks let you create rich, data-driven content by combining your chart data with HTML or Markdown templates. This powerful feature allows you to build custom visualizations, narrative insights, detailed record views, and styled reports that go beyond standard chart types.

Unlike traditional visualizations, Dynamic Content Blocks give you complete control over how your data is presented. You can create executive summaries that highlight key insights, build custom product cards, design detailed customer profiles, or craft any other data-driven content your dashboard needs.

<img src="https://media.holistics.io/e012a1a2-dynamic-content-block-overview.png" alt="Dynamic Content Block Overview" />

## Use Cases

Dynamic Content Blocks are perfect for:

- **Executive summaries**: Highlight top performers and key insights in natural language
- **Custom visualizations**: Build unique chart types not available in standard options (e.g., dumbbell charts, custom timelines)
- **Detailed record views**: Display rich customer or product profiles with images, metrics, and formatting
- **Narrative reporting**: Transform data into storytelling with contextual insights
- **Styled data cards**: Create visually appealing cards with custom layouts and branding
- **KPI dashboards**: Design executive-style metric displays with custom formatting

## How to Create a Dynamic Content Block

Follow these steps to create your first Dynamic Content Block:

<img src="https://media.holistics.io/ad84473f-dynamic-content-block-editor.png" alt="Dynamic Content Block Editor Interface" />

### 1. Add a Visualization Block

Start by adding a new Visualization block to your Canvas Dashboard, just like you would add any other chart.

### 2. Choose Markdown Visualization Type

In the visualization type selector, choose **Markdown** as your chart type. This enables the Dynamic Content Block editor.

### 3. Add Your Data Fields

Drag and drop the data fields you want to use in your template, just like building a Table or Pivot Table:

- Add dimensions (e.g., Product Name, Customer Name, Date)
- Add measures (e.g., Revenue, Order Count, Conversion Rate)
- Apply filters and sorting as needed

Use the **Chart Data** tab to preview your data and ensure it contains the information you need for your template.

### 4. Build Your Template

Switch to the **Editor** tab to start building your template. You can use:

- **HTML**: For complete control over structure and styling
- **Markdown**: For simpler, text-based formatting
- **Mix both**: Combine HTML and Markdown as needed

### 5. Inject Your Data

Use template syntax to inject your data into the content:

- Access row data with `{{ rows[0].`Field Name` }}`
- Loop through rows with `{% map(rows) %} ... {% end %}`
- Apply formatting and conditional logic as needed

The editor provides real-time preview so you can see how your template renders with actual data.

## Template Syntax

### Accessing Data Fields

Reference your data fields using double curly braces with backticks for field names:

```aml
{{ rows[0].`Product Name` }}
{{ rows[0].`Revenue` }}
```

### Accessing Raw Values

For fields that have formatted values (like links or formatted numbers), access the raw value:

```aml
{{ rows[0].`Email`.raw }}
{{ rows[0].`Profile Image URL`.raw }}
```

### Looping Through Rows

Use the `map` function to iterate through all rows in your data:

```aml
{% map(rows) %}
  <div>{{ `Product Name` }}: {{ `Revenue` }}</div>
{% end %}
```

Inside a `map` loop, reference fields directly without the `rows[0]` prefix.

## Examples

### Example 1: E-commerce Conversion Analysis with Key Insights

This example shows how to transform raw e-commerce conversion data into actionable insights by creating a narrative summary that highlights top performers, identifies cart abandonment issues, and surfaces optimization opportunities.

You'll learn how to reference specific rows (`rows[0]`, `rows[1]`), apply conditional styling with color-coded badges (red for high abandonment, green for high conversion), and create business narratives from data. Perfect for executive dashboards, funnel analysis, or any scenario where storytelling enhances data comprehension.

<img src="https://media.holistics.io/a4dc2d7f-dynamic-content-block-ex1.png" alt="E-commerce Conversion Analysis with Key Insights Example" />

```html
<style>
  .insights-badge {
    display: inline-block;
    background: #EFF6FF;
    color: #1E40AF;
    padding: 0.08rem 0.5rem;
    border-radius: 4px;
    font-weight: 600;
    font-size: 0.85rem;
    white-space: nowrap;
  }

  .insights-badge.red {
    background: #FEF2F2;
    color: #DC2626;
  }

  .insights-badge.green {
    background: #F0FDF4;
    color: #16A34A;
  }

  .insights-container {
    padding: 1.5rem;
    max-width: 800px;
    font-size: 0.9rem;
    line-height: 1.6;
    color: #374151;
    background: #FFFFFF;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }

  .insights-container ul {
    margin-top: 0.5rem;
    padding-left: 1.5rem;
    list-style: none;
  }

  .insights-container li {
    margin-bottom: 0.75rem;
  }

  .insights-container li:last-child {
    margin-bottom: 0;
  }
</style>

<div class="insights-container">
  <!-- <p><strong>Key Insights:</strong></p> -->
  <ul>
  <li><p style="margin-bottom: 1rem; line-height: 1.8;">
    <strong>Top Performers:</strong> Dumbbells (<span class="insights-badge">{{ rows[0].`Purchased` }}</span>), Fitness Tracker (<span class="insights-badge">{{ rows[1].`Purchased` }}</span>), and Wireless Headphones (<span class="insights-badge">{{ rows[2].`Purchased` }}</span>) lead in actual sales conversions.
  </p></li>
  <li><p style="margin-bottom: 1rem; line-height: 1.8;">
    <strong>Largest Cart Abandonment:</strong> Exercise Bike shows a big gap with <span class="insights-badge red">{{ rows[3].`Cart abandonment` }} abandoned</span> (<span style="color: #DC2626; font-weight: 600;">{{ rows[3].`Added to cart` }}</span> added vs. <span style="color: #0891F2; font-weight: 600;">{{ rows[3].`Purchased` }}</span> purchased), followed by Resistance Bands (<span class="insights-badge red">{{ rows[4].`Cart abandonment` }} gap</span>) and Yoga Mat (<span class="insights-badge red">{{ rows[5].`Cart abandonment` }} gap</span>).
  </p></li>
  <li><p style="margin-bottom: 1rem; line-height: 1.8;">
    <strong>High Conversion Rate:</strong> Dumbbells demonstrates the strongest purchase intent with only a <span class="insights-badge green">{{ rows[0].`Cart abandonment` }}-unit gap</span>, while Jump Rope (<span class="insights-badge green">{{ rows[6].`Cart abandonment` }} gap</span>) and Fitness Tracker (<span class="insights-badge green">{{ rows[1].`Cart abandonment` }} gap</span>) also show relatively strong conversion.
  </p></li>
  <li><p style="margin-bottom: 0; line-height: 1.8;">
    <strong>Opportunity Area:</strong> Products with <span class="insights-badge red">&gt;200 gap</span> suggest potential for targeted remarketing campaigns or checkout optimization.
  </p></li>
  </ul>
</div>
```

### Example 2: Dumbbell Chart for Conversion Comparison

This example demonstrates how to build a custom dumbbell chart visualization that compares two related metrics (items added to cart vs. purchased) to show conversion gaps at a glance.

You'll learn how to use the `{% map(rows) %}` loop to iterate through data, calculate percentages for positioning visual elements, create custom chart components with CSS, and build visualizations not available in standard chart types. Ideal for funnel analysis, before/after comparisons, or any scenario where you need to visualize the gap between two metrics.

<img src="https://media.holistics.io/06c02ec4-dynamic-content-block-ex2.png" alt="Dumbbell Chart for Conversion Comparison Example" />

```html
<style>
  .dumbbell-container {
    padding: 1.5rem;
    max-width: 800px;
  }

  .dumbbell-row {
    display: grid;
    grid-template-columns: 200px 1fr;
    gap: 1.5rem;
    align-items: center;
    padding: 1rem 0;
    border-bottom: 1px solid #F3F4F6;
  }

  .dumbbell-row:last-child {
    border-bottom: none;
  }

  .dumbbell-label {
    font-size: 0.875rem;
    font-weight: 500;
    color: #374151;
  }

  .dumbbell-plot-area {
    position: relative;
    height: 20px;
    display: flex;
    align-items: center;
  }

  .dumbbell-bar-container {
    position: relative;
    width: 100%;
    height: 100%;
  }

  .dumbbell-line {
    position: absolute;
    height: 8px;
    background: linear-gradient(to right, #0891F2, #F1434B);
    border-radius: 4px;
    opacity: 0.6;
    top: 50%;
    transform: translateY(-50%);
  }

  .dumbbell-dot {
    position: absolute;
    width: 16px;
    height: 16px;
    border-radius: 50%;
    border: 3px solid white;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
    top: 50%;
    transform: translate(-50%, -50%);
    z-index: 2;
  }

  .dumbbell-dot.start {
    background-color: #0891F2;
  }

  .dumbbell-dot.end {
    background-color: #F1434B;
  }

  .dumbbell-value {
    position: absolute;
    font-size: 0.75rem;
    font-weight: 600;
    white-space: nowrap;
    top: 50%;
    transform: translateY(-50%);
  }

  .dumbbell-value.start {
    color: #0891F2;
    transform: translate(calc(-100% - 12px), -50%);
  }

  .dumbbell-value.end {
    color: #F1434B;
    transform: translate(12px, -50%);
  }

  .dumbbell-title {
    padding: 0 0 1rem 0;
    font-size: 1.125rem;
    font-weight: 600;
    color: #111827;
  }

  .dumbbell-legend {
    display: flex;
    gap: 2rem;
    padding: 0 0 0.5rem 0;
    font-size: 0.75rem;
    color: #6B7280;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .legend-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    border: 2px solid white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
  }

  .legend-dot.start {
    background-color: #0891F2;
  }

  .legend-dot.end {
    background-color: #F1434B;
  }

  @media (max-width: 768px) {
    .dumbbell-row {
      grid-template-columns: 1fr;
      gap: 0.5rem;
    }

    .dumbbell-label {
      font-weight: 600;
      padding-bottom: 0.5rem;
    }

    .dumbbell-plot-area {
      height: 60px;
    }
  }
</style>

<!-- <div class="dumbbell-title">Product Performance: Purchases vs. Cart Additions</div> -->

<div class="dumbbell-legend">
  <div class="legend-item">
    <span class="legend-dot start"></span>
    <span>Purchased</span>
  </div>
  <div class="legend-item">
    <span class="legend-dot end"></span>
    <span>Added to Cart</span>
  </div>
</div>

<div class="dumbbell-container">
{% map(rows) %}
  <div class="dumbbell-row">
    <div class="dumbbell-label">{{ `Product name` }}</div>
    <div class="dumbbell-plot-area">
      <div class="dumbbell-bar-container">
        <div class="dumbbell-line" style="left: {{ `Start Percent` }}%; width: {{ `Bar Width` }}%;"></div>
        <div class="dumbbell-dot start" style="left: {{ `Start Percent` }}%;"></div>
        <div class="dumbbell-value start" style="left: {{ `Start Percent` }}%;">{{ `Purchased` }}</div>
        <div class="dumbbell-dot end" style="left: {{ `End Percent` }}%;"></div>
        <div class="dumbbell-value end" style="left: {{ `End Percent` }}%;">{{ `Added to cart` }}</div>
      </div>
    </div>
  </div>
{% end %}
</div>

```

### Example 3: Product Grid with Cards Layout

This example shows how to create a responsive product grid with image thumbnails, metrics, and clean card-based layouts that display multiple items simultaneously.

You'll learn how to loop through multiple rows to create repeated card elements, work with product images using `.raw` values, build responsive grid layouts with CSS Grid, and format metrics with proper labels. Perfect for e-commerce dashboards, product catalogs, inventory displays, or any multi-item overview.

<img src="https://media.holistics.io/a801bd65-dynamic-content-block-ex3.png" alt="Product Grid with Cards Layout Example" />

```html
<style>
  /* https://play.tailwindcss.com/vHqt0FBGy8 */
	.deals-container {
		display: grid;
		padding: 1.5rem; 
		grid-template-columns: repeat(1, minmax(0, 1fr)); 
		column-gap: 1.5rem; 
		row-gap: 2rem; 
		list-style: none;
		grid-template-columns: repeat(1, minmax(0, 1fr)); 
      @media (min-width: 1024px) { 
			grid-template-columns: repeat(2, minmax(0, 1fr)); 
		}
		@media (min-width: 1280px) { 
			grid-template-columns: repeat(2, minmax(0, 1fr)); 
			column-gap: 2rem; 
		}
		@media (min-width: 1536px) { 
			grid-template-columns: repeat(3, minmax(0, 1fr)); 
			column-gap: 2rem; 
		}
		@media (min-width: 1960px) { 
			grid-template-columns: repeat(3, minmax(0, 1fr)); 
			column-gap: 2rem; 
		}
		
	}

	.deal-container {
		overflow: hidden; 
		border-radius: 0.75rem; 
		border: 1px solid #E5E7EB;
		list-style: none;
	}

	.deal-header {
		display: flex; 
		padding: 1.5rem; 
		column-gap: 1rem; 
		align-items: center; 
		border-bottom: 1px solid rgb(17 24 39 / 0.05); 
		background-color: #F9FAFB; 
	}

	.deal-logo {
		object-fit: cover; 
		flex: none; 
		border-radius: 0.5rem;
        border: 1px solid rgb(229 231 235);
		box-shadow: 0 0 0 0 calc(1px) rgb(229 231 235); 
		width: 4rem; 
		height: 4rem; 
		background-color: #ffffff; 
	}

	.deal-name {
		font-size: 1rem;
		line-height: 1.25rem; 
		font-weight: 500; 
		line-height: 1.5rem; 
		color: #111827; 
	}

	.deal-details {
      padding-top: 1rem;
      padding-bottom: 1rem; 
      padding-left: 1.5rem;
      padding-right: 1.5rem; 
      margin-top: -0.75rem;
      margin-bottom: -0.75rem; 
      border-top-width: 1px; 
      border-color: #F3F4F6; 
      font-size: 0.875rem;
      line-height: 1.25rem; 
      line-height: 1.5rem; 
	}

	.deal-details-inner {
      display: flex; 
      padding-top: 0.3rem;
      padding-bottom: 0.3rem; 
      column-gap: 1rem; 
      justify-content: space-between; 
	}

  	/* Tailwind Helpers */
	  .-my-3 {
  margin-top: -0.75rem;
  margin-bottom: -0.75rem;
}
.flex {
  display: flex;
}
.flex-row {
  flex-direction: row;
}
.flex-col {
  flex-direction: column;
}
.grid {
  display: grid;
}
.h-12 {
  height: 3rem;
}
.w-12 {
  width: 3rem;
}
.flex-none {
  flex: none;
}
.grid-cols-1 {
  grid-template-columns: repeat(1, minmax(0, 1fr));
}
.items-start {
  align-items: flex-start;
}
.items-center {
  align-items: center;
}
.justify-between {
  justify-content: space-between;
}
.gap-x-2 {
  column-gap: 0.5rem;
}
.gap-x-4 {
  column-gap: 1rem;
}
.gap-x-6 {
  column-gap: 1.5rem;
}
.gap-y-8 {
  row-gap: 2rem;
}
.divide-y > :not([hidden]) ~ :not([hidden]) {
  border:0;
  border-style: solid;
  border-top-width: 1px;
  border-bottom-width: 1px;
}
.divide-y > div.deal-details-inner:last-of-type {
  border-bottom-width: 0px;
}
.divide-gray-100 > :not([hidden]) ~ :not([hidden]) {
  border-color: rgb(243 244 246);
}
.overflow-hidden {
  overflow: hidden;
}
.rounded-lg {
  border-radius: 0.5rem;
}
.rounded-md {
  border-radius: 0.375rem;
}
.rounded-xl {
  border-radius: 0.75rem;
}
.border {
  border-width: 1px;
}
.border-b {
  border-bottom-width: 1px;
}
.border-gray-200 {
  border-color: rgb(229 231 235);
}
.border-gray-900\/5 {
  border-color: rgb(17 24 39 / 0.05);
}
.bg-gray-50 {
  background-color: rgb(249 250 251);
}
.bg-red-50 {
  background-color: rgb(254 242 242);
}
.bg-white {
  background-color: rgb(255 255 255);
}
.object-cover {
  object-fit: cover;
}
.p-6 {
  padding: 1.5rem;
}
.px-2 {
  padding-left: 0.5rem;
  padding-right: 0.5rem;
}
.px-6 {
  padding-left: 1.5rem;
  padding-right: 1.5rem;
}
.py-1 {
  padding-top: 0.25rem;
  padding-bottom: 0.25rem;
}
.py-3 {
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
}
.py-4 {
  padding-top: 1rem;
  padding-bottom: 1rem;
}
.text-sm {
  font-size: 0.875rem;
  line-height: 1.25rem;
}
.text-xs {
  font-size: 0.75rem;
  line-height: 1rem;
}
.font-medium {
  font-weight: 500;
}
.leading-6 {
  line-height: 1.5rem;
}
.text-gray-500 {
  color: rgb(107 114 128);
}
.text-gray-700 {
  color: rgb(55 65 81);
}
.text-gray-900 {
  color: rgb(17 24 39);
}
.text-red-700 {
  color: rgb(185 28 28);
}
  .px-1 {
    padding-left: 0.25rem;
    padding-right: 0.25rem; 
  }
  .pl-1 {
    padding-left: 0.25rem;
  }
  .pr-1 {
padding-right: 0.25rem; 
  }
  .px-2 {
    padding-left: 0.50rem;
    padding-right: 0.50rem; 
  }
  .pl-2 {
    padding-left: 0.50rem;
  }
  .pr-2 {
padding-right: 0.50rem; 
  }
  
.text-sky-700 {
  color: rgb(3 105 161);
}
  .ring-sky-600\/10 {
  border: 1px solid rgb(2 132 199 / 0.1);
  }
  .bg-sky-50 {
  background-color: rgb(240 249 255);
}
  .ml-2 {
    margin-left: 0.5rem;
  }
  .bg-green-50 {
  background-color: rgb(240 253 244);
}
  .text-green-700 {
  color: rgb(21 128 61);
}
  .ring-green-600\/10 {
  border: 1px solid rgb(22 163 74 / 0.1);;
  }
</style>

<ul class="deals-container">
  
{% map(rows) %}

<li class="deal-container">
<div class="deal-header">
<img src="{{ `Product Image Url`.raw }}" class="deal-logo" alt="{{ `Name` }}">
<section class="deal-name flex flex-col" style="justify-content: start;">
<div class="flex flex-row" style="align-items: center;">{{ `Name` }}
</div>
</div>
</section>
</div>

<dl class="-my-3 divide-y divide-gray-100 px-6 py-4 text-sm leading-6">

<div class="deal-details-inner" style="border-bottom: none;">
<dt class="text-gray-500">Revenue</dt>
<dd class="flex items-start gap-x-2">
<section class="rounded-md ml-2 font-medium ring-1 ring-inset text-green-700 bg-green-50 ring-green-600/10" style="padding: 2px 6px">{{ values.`Revenue` }}</section>
</dd>
</div>

<div class="deal-details-inner">
<dt class="text-gray-500">Category</dt>
<dd class="flex items-start gap-x-2">
<div class="font-medium text-gray-900">{{ `Category Name` }}</div>
</dd>
</div>

<div class="deal-details-inner">
<dt class="text-gray-500">Price</dt>
<dd class="flex items-start gap-x-2">
<div class="font-medium text-gray-900">{{ values.`Total Price` }}</div>
</dd>
</div>

</dd>
</div>
</dl>
</li>

{% end %}

</ul>

```

### Example 4: User Profile Dashboard

This example demonstrates how to create a detailed user profile view that combines a data table with a rich profile card showing personal information, key metrics, and contact details.

You'll learn how to display profile images and handle external links, create metric cards with large numbers and labels, build side-by-side layouts combining tables and detail views, and format status badges with conditional styling. Ideal for CRM dashboards, customer support tools, user management interfaces, or any scenario requiring detailed record views.

<img src="https://media.holistics.io/57897039-dynamic-content-block-ex4.png" alt="User Profile Dashboard Example" />

```html
<style>
  /* Record Lookup Card Styling */
  .record-card {
    max-width: 600px;
    background-color: white;
    border-radius: 12px;
    border: 1px solid #E5E7EB;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  }

  .record-header {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 1.5rem;
    padding: 1.5rem;
    background-color: #F9FAFB;
    border-bottom: 1px solid #E5E7EB;
  }

  .record-image {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid white;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  .record-info {
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 0.375rem;
  }

  .record-name {
    font-size: 1.25rem;
    font-weight: 600;
    color: #111827;
    line-height: 1.3;
  }

  .record-email {
    font-size: 0.875rem;
    color: #6366F1;
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 0.375rem;
  }

  .record-email:hover {
    text-decoration: underline;
  }

  .record-location {
    font-size: 0.875rem;
    color: #6B7280;
    display: flex;
    align-items: center;
    gap: 0.375rem;
  }

  .record-location a {
    color: inherit;
    text-decoration: none;
  }

  .record-location a:hover {
    color: #4B5563;
    text-decoration: underline;
  }

  /* Metrics Section */
  .record-metrics {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    border-bottom: 1px solid #E5E7EB;
  }

  .metric-item {
    padding: 1.25rem;
    text-align: center;
    border-right: 1px solid #E5E7EB;
  }

  .metric-item:last-child {
    border-right: none;
  }

  .metric-value {
    font-size: 1.5rem;
    font-weight: 700;
    color: #111827;
    line-height: 1.2;
  }

  .metric-label {
    font-size: 0.75rem;
    color: #6B7280;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-top: 0.25rem;
  }

  /* Details Section */
  .record-details {
    padding: 1.5rem;
  }

  .detail-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.75rem 0;
    border-bottom: 1px solid #F3F4F6;
  }

  .detail-row:last-child {
    border-bottom: none;
  }

  .detail-label {
    font-size: 0.875rem;
    color: #6B7280;
    font-weight: 500;
  }

  .detail-value {
    font-size: 0.875rem;
    color: #111827;
    font-weight: 600;
  }

  /* Status Badge */
  .status-badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .status-badge.active,
  .status-badge.ACTIVE,
  .status-badge:is([class*="active"], [class*="ACTIVE"]) {
    background-color: #DEF7EC !important;
    color: #047857 !important;
  }

  .status-badge.vip,
  .status-badge.VIP,
  .status-badge:is([class*="vip"], [class*="VIP"]) {
    background-color: #FEF3C7 !important;
    color: #92400E !important;
  }

  .status-badge.new,
  .status-badge.NEW,
  .status-badge:is([class*="new"], [class*="NEW"]) {
    background-color: #DBEAFE !important;
    color: #1E3A8A !important;
  }

  /* Icon Styling */
  .icon {
    display: inline-block;
    width: 16px;
    height: 16px;
  }

  /* Responsive Design */
  @media (max-width: 640px) {
    .record-header {
      grid-template-columns: 1fr;
      text-align: center;
      gap: 1rem;
    }

    .record-image {
      margin: 0 auto;
    }

    .record-email,
    .record-location {
      justify-content: center;
    }

    .record-metrics {
      grid-template-columns: 1fr;
    }

    .metric-item {
      border-right: none;
      border-bottom: 1px solid #E5E7EB;
    }

    .metric-item:last-child {
      border-bottom: none;
    }
  }

  /* Empty State */
  .empty-state {
    padding: 3rem 1.5rem;
    text-align: center;
    color: #9CA3AF;
  }

  .empty-state-title {
    font-size: 1.125rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
  }

  .empty-state-text {
    font-size: 0.875rem;
  }
</style>

<div class="record-card">

<!-- Header Section -->
<div class="record-header">
<img src="{{ rows.0.`Profile Image URL`.raw }}" alt="{{ rows.0.`Full Name` }}" class="record-image" />

<div class="record-info">
<div class="record-name">{{ rows.0.`Full Name` }}</div>

<a href="mailto:{{ rows.0.`Email`.raw }}" class="record-email">
  <span class="icon">✉️</span>
  {{ rows.0.`Email` }}
</a>

<div class="record-location">
  <span class="icon">📍</span>
  <a href="https://www.google.com/maps/search/?api=1&query={{ rows.0.`Location`.raw }}" target="_blank" rel="noopener">
    {{ rows.0.`Location` }}
  </a>
</div>
</div>
</div>

<!-- Metrics Section -->
<div class="record-metrics">
  <div class="metric-item">
    <div class="metric-value">{{ rows.0.values.`Total Orders` }}</div>
    <div class="metric-label">Total Orders</div>
  </div>

  <div class="metric-item">
    <div class="metric-value">{{ rows.0.values.`Lifetime Value` }}</div>
    <div class="metric-label">Lifetime Value</div>
  </div>

  <div class="metric-item">
    <div class="metric-value">{{ rows.0.values.`Avg Order Value` }}</div>
    <div class="metric-label">Avg Order</div>
  </div>
</div>

<!-- Details Section -->
<div class="record-details">

  <div class="detail-row">
    <span class="detail-label">Status</span>
    <span class="status-badge {{ rows.0.`Status`.raw  }}">{{ rows.0.`Status` }}</span>
  </div>
  
  <div class="detail-row">
    <span class="detail-label">Member Since</span>
    <span class="detail-value">{{ rows.0.`Member Since` }}</span>
  </div>

  <div class="detail-row">
    <span class="detail-label">Last Order</span>
    <span class="detail-value">{{ rows.0.`Last Order Date` }}</span>
  </div>

  <div class="detail-row">
    <span class="detail-label">User ID</span>
    <span class="detail-value">{{ rows.0.`User ID` }}</span>
  </div>
</div>
</div>

```

## Best Practices

1. **Start with your data**: Build and validate your dataset first using the Chart Data preview before creating your template
2. **Use the Chart Data tab**: Preview your data structure to understand field names and values
3. **Test with real data**: Use the live preview to see how your template renders with actual data
4. **Keep CSS scoped**: Use specific class names to avoid conflicts with other dashboard elements
5. **Handle missing data**: Test your template with incomplete data to ensure it fails gracefully
6. **Optimize performance**: For large datasets, consider limiting rows or using filters to reduce data volume
7. **Mobile responsive**: Use responsive CSS techniques if your dashboard will be viewed on mobile devices

## Tips and Tricks

### Accessing Aggregated Values

Use the `.values` accessor for aggregated metrics:

```aml
{{ rows[0].values.`Total Revenue` }}
{{ rows[0].values.`Average Order Value` }}
```

### Conditional Styling

Apply CSS classes dynamically based on data values:

```html
<div class="status-badge {{ rows[0].`Status`.raw }}">
  {{ rows[0].`Status` }}
</div>
```

### Working with Images

Always use `.raw` for image URLs to get the unformatted value:

```html
<img src="{{ rows[0].`Image URL`.raw }}" alt="Product" />
```

### Creating Links

Build dynamic links with data values:

```html
<a href="mailto:{{ rows[0].`Email`.raw }}">{{ rows[0].`Email` }}</a>
<a href="https://example.com/product/{{ rows[0].`Product ID`.raw }}">View Details</a>
```

## Troubleshooting

### Template not rendering

If your template isn't showing up:

- Check for syntax errors in your HTML/Markdown
- Ensure field names match exactly (case-sensitive) with backticks
- Verify your data query returns results in the Chart Data tab

### Data not displaying

If data fields show as empty:

- Confirm field names use backticks: `` `Field Name` ``
- Check if you need `.raw` for unformatted values
- Verify the row index exists (e.g., `rows[0]` requires at least one row)

### Styling conflicts

If your styles aren't applying:

- Use specific CSS class names to avoid conflicts
- Check browser developer tools for CSS specificity issues
- Ensure your `<style>` block is included in the template

### Loop not working

If your `map` loop isn't iterating:

- Verify the syntax: `{% map(rows) %} ... {% end %}`
- Inside loops, reference fields without `rows[0]`: just `` `Field Name` ``
- Check that your data has multiple rows to iterate over