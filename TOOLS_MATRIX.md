# Tools & Versions Matrix

### Python Package Groups

| Group | Package | Pin |
|-------|---------|-----|
| core | numpy | 1.26.* |
| core | pandas | 2.2.* |
| core | matplotlib | 3.8.* |
| core | seaborn | 0.13.* |
| core | scipy | 1.11.* |
| ml | torch | 2.2.* |
| ml | torchvision | 0.17.* |
| ml | torchaudio | 2.2.* |
| ml | scikit-learn | 1.4.* |
| ml | jupyter | 1.0.* |
| ml | jupyterlab | 4.1.* |
| ml | xgboost | 2.1.* |
| ml | lightgbm | 4.3.* |
| ml | catboost | 1.2.* |
| ml | imbalanced-learn | 0.12.* |
| ml | yellowbrick | 1.5.* |
| ml | optuna | 3.6.* |
| ml | hyperopt | 0.2.* |
| web | django | 5.0.* |
| web | djangorestframework | 3.15.* |
| web | flask | 3.0.* |
| web | fastapi | 0.112.* |
| web | uvicorn | 0.30.* |
| web | requests | 2.32.* |
| web | beautifulsoup4 | 4.12.* |
| web | selenium | 4.23.* |
| web | pytest | 8.3.* |
| db | psycopg2-binary | 2.9.* |
| db | aiosqlite | 0.20.* |
| db | pymysql | 1.1.* |
| db | pymongo | 4.8.* |
| db | redis | 5.0.* |
| viz | plotly | 5.22.* |
| viz | bokeh | 3.4.* |
| viz | altair | 5.2.* |
| viz | dash | 2.17.* |
| viz | panel | 1.4.* |
| viz | streamlit | 1.36.* |
| nlp | nltk | 3.9.* |
| nlp | spacy | 3.7.* |
| nlp | transformers | 4.43.* |
| nlp | datasets | 2.20.* |
| cv | opencv-python | 4.10.* |
| cv | Pillow | 10.3.* |
| cv | scikit-image | 0.23.* |

### Node Global Packages

| Package | Pin |
|---------|-----|
| typescript | 5.4.* |
| yarn | 1.22.* |
| pnpm | 8.15.* |
| create-react-app | 5.0.* |
| nodemon | 3.1.* |
| concurrently | 8.2.* |
| http-server | 14.1.* |
| live-server | 1.2.* |
| jest | 29.7.* |
| cypress | 13.13.* |
| playwright | 1.47.* |
| webpack | 5.92.* |
| webpack-cli | 5.1.* |
| parcel | 2.12.* |
| vite | 5.3.* |
| eslint | 8.57.* |
| prettier | 3.3.* |
| stylelint | 16.6.* |
| appium | 2.11.* |
| appium-doctor | 1.19.* |
| detox-cli | 0.0.* # update when stable pin decided |
| react-devtools | 5.0.* |

### Profiles

| Profile | Python Groups | Node Globals |
|---------|---------------|--------------|
| minimal | core | typescript |
| full | core,ml,viz | typescript,yarn,pnpm,create-react-app,'@vue/cli','@angular/cli',nodemon,concurrently,http-server,live-server,jest,cypress,playwright,webpack,webpack-cli,parcel,vite,eslint,prettier,stylelint |

