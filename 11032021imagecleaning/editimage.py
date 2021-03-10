from helpermethods import convolve, invert, mean_filter, median_filter
import numpy as np
from skimage import io

# The enhancement filters to use
laplacian_filter = np.array([[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]])
sharpen_filter = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
# The (approximated) Gaussian blur filters to use
gauss3 = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]], dtype=np.float)
gauss3 *= 1/16
gauss5 = np.array([[1, 4, 6, 4, 1],
                   [4, 16, 24, 16, 4],
                   [6, 24, 36, 24, 6],
                   [4, 16, 24, 16, 4],
                   [1, 4, 6, 4, 1]], dtype=np.float)
gauss5 *= 1/256
# Load the image
image = io.imread("<image file path>")
print("Loaded image")

# Apply a filter
# edited = convolve(image, laplacian_filter, "Applied Laplacian filter")
# edited = convolve(image, sharpen_filter, "Applied Sharpen-filter")
# edited = convolve(image, gauss3, "Applied Gaussian (3 x 3) blur")
# edited = convolve(image, gauss5, "Applied Gaussian (5 x 5) blur")
edited = mean_filter(image, neighbourhood_size=5)
# edited = median_filter(image)
# edited = invert(image)

# Show the results
io.imshow(edited)
io.show()
