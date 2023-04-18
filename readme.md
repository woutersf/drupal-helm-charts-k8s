
# 1 Configure the site repo

## 1.1 Drupal site repo configuration
in your drupal repo create a *helm* folder with the following structure:

````
helm
├── Chart.yaml
├── disabled
│  └── jobs.yml (just an example)
├── etc -> Symlink to etc folder in repository.
├── templates 
│  ├── cronjob_consumer.yaml (just an example)
│  └── ingress.yaml (just an example)
├── values-acc.yaml
├── values-prd.yaml
└── values-tst.yaml
````

## 1.2 Helm files values (values-tst.yaml)
Create the needed *values-tst.yaml* files based on the *values-env.yaml* in this repository.
Replace
- companydivision
- applicationid
- applicationid.domain.io
- NR_LICENSE_KEY
- ghcr.io/organisation/php-fpm-applicationid
- ghcr.io/organisation/nginx-applicationid
- ghcr.io/organisation/cypress-applicationid
- githubEMAIL
- GITHUBPASS
With real values that can be used. 

Also check the maintenance configuration wich currently is hardcoded in the chart. 
This is something that will change later.

## 1.3 Extra information
The Disabled folder contains disabled helm charts. 
The Templates folder contains the active templates that will be activated on Deploy.

# 2. Configure your CICD
checkout this repo, and overwrite the files you wish to overwrite from your repo.
like so: 

````
      ## PREP  HELM CODE
      - name: Checkout helm repo
        uses: actions/checkout@v3
        with:
          repository: woutersf/drupal-helm-charts-k8s
          path: upstream_helm
          token: ${{ secrets.GIT_CHECKOUT_TOKEN }}
          ref: '${{ inputs.aks_branch }}'

      # the overrides from the Drupal site repo (cp -n -v)
      - name: Mv in infra helm
        run: |
          echo "Copy from upstream HELM into helm folder.";
          cp -n -v upstream_helm/templates/* helm/templates;
          rm -rf helm/etc/drupal/*.gz
      ## END HELM INFRA CODE PULL IN

      # Validate helm stuff to not leave a broken state.
      - name: DRY RUN
        run: |
          cd helm
          helm upgrade --dry-run --timeout 15m --install -n ${{ inputs.app_key }}-${{ inputs.environment }} -f values-${{ inputs.environment }}.yaml --set deploy.runid=${{ github.run_id }} --set image.tag=${{ inputs.version }}  --set image.version=${{ inputs.version }}  ${{ inputs.app_key }} .

````

# 3. Understanding the yaml files
The helm manual is a great place to get more details: https://helm.sh/docs/topics/charts/

If you have no Idea what these yamls do, check this blog post.
https://dropsolid.io/knowledge-hub/kubernetes-terminology or 


