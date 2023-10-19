import geopandas as gpd
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import warnings

warnings.filterwarnings("ignore")

# Load datasets
pois = gpd.read_file('/app/data/input/amenities_costanera')
grid = gpd.read_file('/app/data/input/grilla')
pat = gpd.read_file('/app/data/input/pois_patentes_comerciales.geojson')

pat_intersection = gpd.sjoin(pat, grid, how="left", op="intersects")
pat_intersection.dropna(subset=['grid_id'], inplace=True)
delete_types = ['INDUSTRIAL', 'PROFESIONAL ', 'PROVISORIA']
pat_intersection = pat_intersection[~pat_intersection['type'].isin(delete_types)]

df = pd.read_csv('/app/data/input/patentes_comerciales_amenities_labels.csv')
df = df[~df['category'].isin(['No clasificado', 'drop'])]
df = df[['name', 'category']].drop_duplicates()

pat_with_categories = pd.merge(pat_intersection, df, on='name')
pat_with_categories.rename(columns={'id_left': 'id'}, inplace=True)
pat_with_categories['source'] = 'SII'
pat_with_categories = pat_with_categories[pois.columns]

mask = pois.Subcategor.isna()
pois.loc[mask, 'name'] = 'Mall Costanera'
pois.loc[mask, 'source'] = 'CityLab'
pois.loc[mask, 'id'] = '202310' + pois[mask].index.astype(str)

pois = pd.concat([pois, pat_with_categories])

pois.to_file('/app/data/input/amenities_costanera_v2')