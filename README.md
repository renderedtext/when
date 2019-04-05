# when

# Promote automatically always

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: true
```    

# Promote automatically on any branch and any result

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "branch = * AND result = *"
```

# Promote automatically on any branch and result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "branch = * AND result = passed"
```

# Promote automatically only when master result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "branch = master AND result = passed"
```

# Promote automatically only master branch

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "branch = master"
```

# Promote automatically all branches that start with “df/”

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "branch ~= 'df/*'"
```

# Promote automatically on staging or master branches

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: branch = staging OR branch = master
```

# Allow manual promotion only on master branch

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow: 
      when: branch = master
```

# Allow manual promotion only if result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow: 
      when: result = passed
```

# Allow manual promotion only on tags

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow: 
      when: tag = *
```

# Allow manual promotion only on tags and result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow: 
      when: tag = * and result = passed
```

# Promote automatically on any tag

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: tag = *
```

# Promote automatically if tag matches “v1.*”

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "tag ~= 'v1.*'"
```


# Promote automatically if tag matches “v1.*” and result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "tag ~= 'v1.*' AND result = passed"
```

# Promote automatically on master branch and tags

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto: 
      when: "branch = master OR tag = *"
```
