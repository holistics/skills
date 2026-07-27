---
name: analyze-contribution-generate-viz
description: |-
  Template for visualizing analyze-contribution's calculations. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

- `[base_period_name]` and `[comparison_period_name]` — human-readable period names
- Strictly follow the template below

```
CombinationChart {
  dataset: [dataset_uname]
  calculation base_value {
    label: '[base_period_name]'
    formula: @aql [base_period_metric] ;;
    calc_type: 'measure'
    data_type: 'number'
  }
  calculation comparison_value {
    label: '[comparison_period_name]'
    formula: @aql [comparison_period_metric] ;;
    calc_type: 'measure'
    data_type: 'number'
  }
  calculation delta_value {
    label: 'Δ Change'
    formula: @aql [delta_metric] ;;
    calc_type: 'measure'
    data_type: 'number'
  }
  x_axis: VizFieldFull {
    label: '[dimension_label]'
    ref: r([dimension_field_ref])
    format {
      type: 'text'
    }
  }
  y_axis {
    label: '[metric_name]'
    series {
      mark_type: 'column'
      field: VizFieldFull {
        label: '[base_period_name]'
        ref: 'base_value'
        format {
          type: 'number'
        }
      }
      settings {
        color: '#255DD4'
      }
    }
    series {
      mark_type: 'column'
      field: VizFieldFull {
        label: '[comparison_period_name]'
        ref: 'comparison_value'
        format {
          type: 'number'
        }
      }
      settings {
        color: '#92AEEA'
      }
    }
  }
  y_axis {
    label: 'Δ Change'
    settings {
      alignment: 'right'
    }
    series {
      mark_type: 'line'
      field: VizFieldFull {
        label: 'Δ Change'
        ref: 'delta_value'
        format {
          type: 'number'
        }
      }
      settings {
        color: '#1F3864'
        line_interpolation: 'smooth'
      }
    }
  }
  conditions: [
    ...
  ]
  settings {
    sort {
      field_index: 2
      direction: '[sort_direction]'
      type: 'series'
    }
    legend_label: 'top'
    x_axis_label: '[dimension_label]'
  }
}
```