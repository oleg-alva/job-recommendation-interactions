# DBT Project Template

This is a template for creating new dbt projects with a standardized structure.

## Project Structure

```
project_name/
  analyses/
  macros/
  models/
    core/
    metrics/
    staging/
  seeds/
  snapshots/
  tests/
  dbt_project.yml
```

## Getting Started

### 1. Project Setup

1. Clone this template repository
2. Rename the project:
   - Update `name` in `dbt_project.yml`
   - Update `profile` in `dbt_project.yml`
   - Update the models config section in `dbt_project.yml` to match your project name
3. Update templated files:
   - Search for and replace `project_name` in all files #TODO reimplement with Jinja? 
   - Modify `models/schema.yml` with your model configurations
   - Review and update any `.sql` files in the `models/` directory
   - Update test cases in `tests/` directory 
4. Set up a GCP service account and add the keyfile to the root of the project

### 2. Profile Configuration

Create a profile in your `~/.dbt/profiles.yml`:

```yaml
project_name: # Should match the profile name in dbt_project.yml
target: dev
outputs:
dev:
type: bigquery
```

### 3. Project Structure

- `models/staging/`: Raw data transformations
- `models/core/`: Business logic transformations
- `models/metrics/`: Metric calculations and aggregations
- `analyses/`: Ad-hoc analyses
- `macros/`: Reusable SQL functions
- `seeds/`: Static data files
- `snapshots/`: Type 2 SCD tracking
- `tests/`: Custom data tests

### 4. Model Materialization

All models are configured to materialize as tables by default. Modify the materialization settings in `dbt_project.yml` as needed for your use case.

## Development Guidelines

1. Follow [dbt best practices](https://docs.getdbt.com/guides/best-practices)
2. Use consistent naming conventions
3. Document your models using dbt docs
4. Write tests for your models

## Dependencies

- dbt-core
- (List any additional packages you're using)
