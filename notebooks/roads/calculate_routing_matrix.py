import geopandas as gpd
import pandas as pd
import pandana as pdna
import osmnx as ox
import numpy as np
import warnings

# Desactivar todas las advertencias
warnings.filterwarnings("ignore")

# Functions
def get_path(source ,feature, mode='caminata'):
    return f'/app/data/{source}/red_escenario_futuro/{mode}/{feature}_conce'
def get_input_nodes():
    return get_path('input', 'nodes')
def get_input_edges():
    return get_path('input', 'edges')
def get_output_nodes():
    return get_path('output', 'nodes')
def get_output_edges():
    return get_path('output', 'edges')

def adjust_nodes_df_to_pandana(nodes_df):
    nodes = pd.DataFrame(
    {
        'osmid': nodes_df['osmid'].astype(int),
        'lat' : nodes_df.geometry.y.astype(float),
        'lon' : nodes_df.geometry.x.astype(float),
        'y' : nodes_df.geometry.y.astype(float),
        'x' : nodes_df.geometry.x.astype(float),
    }
    )
    nodes['id'] = nodes['osmid'].values

    nodes = gpd.GeoDataFrame(data=nodes, geometry=nodes_df.geometry)
    nodes.set_index('osmid', inplace=True)
    return nodes

def adjust_edges_df_to_pandana(edges_df):
    edges = pd.DataFrame(
    {
        'u': edges_df['u'].astype(int),
        'v': edges_df['v'].astype(int),
        'from': edges_df['u'].astype(int),
        'to': edges_df['v'].astype(int),
        'osmid': edges_df['osmid'].astype(int),
        'length': edges_df['length'].astype(float)
    }
    )
    edges['key'] = 0
    edges['key'] = edges['key'].astype(int)
    edges = gpd.GeoDataFrame(data=edges, geometry=edges_df.geometry)
    edges.set_index(['u', 'v', 'key'], inplace=True)
    return edges

def create_net(nodes, edges):
    return pdna.Network(
        nodes['lon'],
        nodes['lat'],
        edges['from'],
        edges['to'],
        edges[['length']]
    )

def main():
    nodes_df = gpd.read_file(get_output_nodes())
    edges_df = gpd.read_file(get_output_edges())

    nodes = adjust_nodes_df_to_pandana(nodes_df)
    edges = adjust_edges_df_to_pandana(edges_df)

    net = create_net(nodes, edges)

    # Process to calculate net's routing matrix
    node_ids = list(net.node_ids)

    total_nodes = len(node_ids)
    dict_lenghts = {}

    batch_size = 1000
    num_batches = total_nodes // batch_size
    batch = 1

    for n in range(total_nodes):
        actual_node = node_ids[n]

        nodes_destination = node_ids[n:]
        node_source = [actual_node]*len(nodes_destination)
        lengths = net.shortest_path_lengths(node_source, nodes_destination)

        dict_lenghts[actual_node] = {node: length for node, length in zip(nodes_destination, lengths)}

        if n%batch_size==0:
            routing_matrix = pd.DataFrame.from_dict(dict_lenghts)
            routing_matrix = routing_matrix.transpose()
            routing_matrix.to_pickle(f'/app/data/output/routing_matrix_batch_{batch}.pkl')
            batch += 1
            del dict_lenghts, routing_matrix
    
    routing_matrix = pd.DataFrame.from_dict(dict_lenghts)
    routing_matrix = routing_matrix.transpose()
    routing_matrix.to_pickle(f'/app/data/output/routing_matrix_batch_{batch}.pkl')
    pass

if __name__=='__main__':
    main()