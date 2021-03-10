import math
from statistics import median
import numpy as np

_convolution = "Convolution"
_median = "Median"


# Given an image and a kernel, this method applies that kernel to the image and prints a message upon finishing
# Will either do a convolution or median filter
def _apply_kernel(img, kernel, mode, success_message):
    # a copy of the image
    image = np.copy(img)
    # the width and height of the image
    height, width = image.shape[0], image.shape[1]
    # the width and height of the kernel
    kheight, kwidth = len(kernel), len(kernel[0])
    # the centre points of the kernel
    centre_x, centre_y = math.floor(kwidth / 2), math.floor(kheight / 2)
    # pixel dimension and data type
    dimension, dtype = len(img[0][0]), img[0][0].dtype

    # for each row...
    for y in range(0, height - kheight):
        # calculate the centre-y position for this iteration
        current_centre_y = y + centre_y

        # for each column...
        for x in range(0, width - kwidth):
            # calculate the centre-x position for this iteration
            current_centre_x = x + centre_x

            # if this is for a convolution filter...
            if mode == _convolution:
                # reset the sum of the product values to 0
                # In the case of dimension > 0 (e.g. RGB images), sum_of_prod will change from int to numpy array
                sum_of_prod = 0

                # apply the convolution filter on the neighbouring pixels to accumulate the product of the two matrices
                for ky in range(kheight):
                    for kx in range(kwidth):
                        sum_of_prod = sum_of_prod + (img[y + ky][x + kx] * kernel[ky][kx])

                # make the centre point of this kernel-overlaying matrix the sum of the product values
                image[current_centre_y][current_centre_x] = sum_of_prod

            # if this is for a median filter...
            if mode == _median:
                # keep a list of the neighbouring pixel values
                values = list()

                # add the values that overlap with the kernel to the new list
                for ky in range(kheight):
                    for kx in range(kwidth):
                        values.append(img[y + ky][x + kx])

                # in case of RGB images, values will be a 2D array
                if dimension == 1:
                    # make the centre point of this kernel-overlaying matrix the median of the values gathered
                    image[current_centre_y][current_centre_x] = median(values)
                else:
                    np_val = np.array(values)
                    # the median array to set for the centre point of the kernel
                    to_set = np.zeros(dimension, dtype=dtype)
                    for dim in range(dimension):
                        to_set[dim] = median(np_val[:, dim])
                    image[current_centre_y][current_centre_x] = to_set

    # finish method by printing a message and returning the edited image
    print(success_message)
    return image


# Applies a convolution filter to an image
def convolve(img, kernel, success_message="Finished applying kernel"):
    return _apply_kernel(img, kernel, _convolution, success_message)


# Applies a median filter to an image
def median_filter(image, neighbourhood_size=3):
    return _apply_kernel(image, np.ones((neighbourhood_size, neighbourhood_size)), _median,
                         "Applied Median filter, Size " + str(neighbourhood_size))


# Applies a mean filter to an image
def mean_filter(image, neighbourhood_size=3):
    # determine value for each of the kernel's elements
    fraction = 1 / (neighbourhood_size ** 2)
    # create the kernel
    kernel = np.array([[fraction] * neighbourhood_size] * neighbourhood_size)
    # apply the kernel using the convolve method and return the edited image
    return convolve(image, kernel, "Applied Mean filter, Size " + str(neighbourhood_size))


# Inverts an image
def invert(img, success_message="Finished inverting image"):
    # a copy of the image
    image = np.copy(img)
    # the width and height of the image
    height, width = image.shape[0], image.shape[1]
    # pixel dimension and data type
    dimension, dtype = len(img[0][0]), img[0][0].dtype
    # invert function
    invert_pixel = lambda p: 255 - p

    # for each row...
    for y in range(0, height):
        # for each column...
        for x in range(0, width):
            # If not RGB, simply invert single pixel value
            if dimension == 1:
                image[y][x] = invert_pixel(img[y][x])
            # else need to invert each RGB value of pixel array
            else:
                to_set = np.zeros(dimension, dtype=dtype)
                # loops through R, G & B parts of current pixel
                for dim in range(dimension):
                    to_set[dim] = invert_pixel(img[y][x][dim])
                image[y][x] = to_set

    # finish method by printing a message and returning the edited image
    print(success_message)
    return image
