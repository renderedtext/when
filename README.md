# when

# Promotions

## Promote automatically always

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "true"
```    

## Promote automatically on any branch and any result

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch =~ '.*' AND. result =~ '.*'"
```

## Promote automatically on any branch and result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch =~ '.*' AND result = 'passed'"
```

## Promote automatically only when master result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch = 'master' AND result = 'passed'"
```

## Promote automatically only master branch

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch = 'master'"
```

## Promote automatically all branches that start with “df/”

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch =~ '^df\/'"
```

## Promote automatically on staging or master branches

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch = 'staging' OR branch = 'master'"
```

## Allow manual promotion only on master branch

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow:
      when: "branch = 'master'"
```

## Allow manual promotion only if result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow:
      when: "result = 'passed'"
```

## Allow manual promotion only on tags

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow:
      when: 'tag =~ '.*''
```

## Allow manual promotion only on tags and result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    allow:
      when: "tag =~ '.*' and result = 'passed'"
```

## Promote automatically on any tag

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "tag =~ '.*'"
```

## Promote automatically if tag starts with “v1.”

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "tag =~ '^v1\.'"
```


## Promote automatically if tag starts with "v1." and result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "tag =~ '^v1\.' AND result = 'passed'"
```

## Promote automatically on master branch and tags

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "branch = 'master' OR tag =~ '.*'"
```

## Promote automatically on master branch and tags when the result is passed

```yaml
promotions:
  - name: Deploy to production
    pipeline_file: prod.yml
    auto:
      when: "(branch = 'master' OR tag =~ '.*') AND result = 'passed'"
```

# Skip block exection

## Skip always

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "true"
```

## Skip on any branch

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "branch = '.*'"
```

## Skip when master

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "branch = 'master'"
```

## Skip when branch starts with “df/”

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "branch =~ '^df\/'"
```

## Skip when branch is staging or master

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "branch = 'staging' OR branch = 'master'"
```

## Skip on any tag

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "tag = '.*'"
```

## Skip when tag start with “v1.”

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "tag =~ '^v1\.'"
```

## Skip on master branch and any tags

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "branch = 'master' OR tag = '.*'"
```

## Execute when branch starts with “dev/” == Skip when branch doesn’t start with dev/

```yaml
blocks:
  - name: Unit tests
    skip:
      when: "branch !~ '^dev\/'"
```

# Fail-fast

## Stop running blocks *

## Cancel pending blocks when a block fails

```yaml
fail-fast:
  cancel:
    when: "true"
```

## Cancel pending blocks when a block fails and on master branch

```yaml
fail-fast:
  cancel:
    when: "branch = 'master'"
```

## Cancel pending blocks when a block fails and branch starts with “df/”

```yaml
fail-fast:
  cancel:
    when: "branch =~ '^df\/'"
```

## Cancel pending blocks when a block fails and branch is staging or master

```yaml
fail-fast:
  cancel:
    when: "branch = 'staging' OR branch = 'master'"
```

## Cancel pending blocks when a block fails and on any tag

```yaml
fail-fast:
  cancel:
    when: "tag =~ '.*'"
```

## Cancel pending blocks when a block fails and tag starts with “v1.”

```yaml
fail-fast:
  cancel:
    when: "tag =~ '^v1\.'"
```


## Cancel pending blocks when a block fails and branch is master or any tag

```yaml
fail-fast:
  cancel:
    when: "branch = 'master' OR tag =~ '.*'"
```

## Cancel pending blocks when a block fails and branch doesn’t start with “dev/”

```yaml
fail-fast:
  cancel:
    when: "tag !~ '^dev\/'"
```

# Scheduling strategies

```yaml
queue:
  mode:
    stop:
      when: "branch = 'master' OR tag =~ '.*'"
    cancel:
      when: "tag =~ '.*'"
```
