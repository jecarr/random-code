from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import dijkstra
import numpy as np

# Task: Generate length of shortest path from top-left to bottom right of map
# Walkable = 0; Obstacle = 1
# Can move only 1 wall
# Map height, weight: 1 < h, w < 21
# Full description here https://stackoverflow.com/questions/41235097

node_count = 0

def solution(map):
    # array of shortest paths, start with any complete path
    found = [get_path(map)]
    # not efficient but for time's sake, find all positions of obstacles
    obstacles = np.argwhere(np.array(map) == 1)
    # and temporarily replace with value of 0 to find shortest path again
    # People have posted this issue on stackoverflow, worth reading up to see more efficient approaches
    for pos in obstacles:
        map[pos[0]][pos[1]] = 0
        # Attempt to beat current shortest path with temp obstacle removed
        found.append(get_path(map, shorter_path_than=min(found)))
        map[pos[0]][pos[1]] = 1
    # return minimum path found
    return int(min(found))

# Method to find the shortest path given a map
def get_path(map, shorter_path_than=None):
    global node_count

    # If no limit is specified, set it to no more than 2 obstacles 
    if shorter_path_than is None:
    	shorter_path_than = 2 * node_count

    adj_matrix = get_adj_matrix(map)
    graph = csr_matrix(adj_matrix)
    dist_matrix = dijkstra(csgraph=graph, indices=0, limit=shorter_path_than)
    # Return only the last distance + 1 to include end node
    return dist_matrix[node_count - 1] + 1

# Method to get the adjacency matrix for the map (to represent as a graph)
def get_adj_matrix(map):
    global node_count

    # Set up the adjacency matrix (initially all 0s) 
    dim = np.array(map).shape
    map_h, map_w = dim[0], dim[1]
    node_count = map_h * map_w
    adj_matrix = np.zeros((node_count, node_count))

    # index for the current node in the adjacent matrix
    idx = 0

    for h, row in enumerate(map):
        for w, elem in enumerate(row):
            # If this node is already an obstacle (i.e. value is 1) 
            # then let the weight be the node count (a significantly larger value)
            weight_elem = 1 if elem == 0 else node_count
            weight_neighbour = None

            # Inspect neighbour nodes
            north = getelem(map, w, h - 1)
            south = getelem(map, w, h + 1)
            east = getelem(map, w + 1, h)
            west = getelem(map, w - 1, h)

            if north == 0 or north == 1:  # we have a value
                weight_neighbour = 1 if north == 0 else node_count
                # Assign the largest weight to the correct node this current one aligns with
                # Moving north is -width of map
                adj_matrix[idx][idx - map_w] = max(weight_elem, weight_neighbour)
                adj_matrix[idx - map_w][idx] = max(weight_elem, weight_neighbour)
            # Repeat for south neighbour
            if south == 0 or south == 1:
                weight_neighbour = 1 if south == 0 else node_count
                adj_matrix[idx][idx + map_w] = max(weight_elem, weight_neighbour)
                adj_matrix[idx + map_w][idx] = max(weight_elem, weight_neighbour)
            # Repeat for east neighbour
            if east == 0 or east == 1:
                weight_neighbour = 1 if east == 0 else node_count
                adj_matrix[idx][idx + 1] = max(weight_elem, weight_neighbour)
                adj_matrix[idx + 1][idx] = max(weight_elem, weight_neighbour)
            # Repeat for west neighbour
            if west == 0 or west == 1:
                weight_neighbour = 1 if west == 0 else node_count
                adj_matrix[idx][idx - 1] = max(weight_elem, weight_neighbour)
                adj_matrix[idx - 1][idx] = max(weight_elem, weight_neighbour)

            # update idx for future equations
            idx = idx + 1

    # Return final adjacency matrix
    return adj_matrix

# Safe method to get map element, returns -1 when no element is found
def getelem(map, w, h):
    try:
        # Do not allow negative index (last-from) access
        if w < 0 or h < 0:
            raise IndexError
        # Return the element
        return map[h][w]
    except IndexError:
        return -1


print(solution([[0, 1, 1, 0], [0, 0, 0, 1], [1, 1, 0, 0], [1, 1, 1, 0]]))  # Expecting 7
print(solution([[0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 1, 0], [0, 0, 0, 0, 0, 0], [0, 1, 1, 1, 1, 1], [0, 1, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0]]))  # Expecting 11

# 0 1 1 0
# 0 0 0 1
# 1 1 0 0
# 1 1 1 0

# 7

# 0 0 0 0 0 0
# 1 1 1 1 1 0
# 0 0 0 0 0 0
# 0 1 1 1 1 1
# 0 1 1 1 1 1
# 0 0 0 0 0 0

# 11