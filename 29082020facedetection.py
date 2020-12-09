from filepaths import image_2_2_folder
from skimage import io
from sklearn import metrics
from sklearn.naive_bayes import GaussianNB
import csv
import math
import matplotlib.pyplot as plt
import os

# Parent directory paths for the train and test data
# Could have used os.path.join() as used later on
root_path = image_2_2_folder + "/"
train_path = root_path + "train/"
test_path = root_path + "test/"
face_path = "face"
non_face_path = "non-face"
# The fixed width and height for the images
size = 19
# The datasets
train = list()
test = list()
train_features = list()
test_features = list()
train_classes = list()
test_classes = list()
# Variables to use in control flow
_add_train = "TRAIN"
_add_test = "TEST"


# Method to create a feature vector from an image
def construct_instance(filepath, class_val, mode):
    # Load the image
    image = io.imread(filepath)
    # Task required 8 features
    freq_lbp = frequent_lbp(image, 1, 8)
    top_left = lbp(image, 3, 3, 2, 16)
    top_right = lbp(image, 3, 15, 2, 16)
    between_brow = lbp(image, 3, 9, 3, 8)
    mid_image = lbp(image, 9, 9, 3, 8)
    mid_lip = lbp(image, 15, 9, 2, 4)
    bottom_left = lbp(image, 15, 3, 2, 4)
    bottom_right = lbp(image, 15, 15, 2, 4)
    # Combine the features with the class value to produce the vector
    feature_vals = [freq_lbp, top_left, top_right, between_brow, mid_image, mid_lip, bottom_left, bottom_right]
    vals = list(feature_vals)
    vals.append(class_val)
    # Append the vector to the appropriate list
    if mode == _add_train:
        train.append(vals)
        train_features.append(feature_vals)
        train_classes.append(class_val)
    elif mode == _add_test:
        test.append(vals)
        test_features.append(feature_vals)
        test_classes.append(class_val)


# Method to obtain the local binary pattern for a given pixel
def lbp(image, row, col, radius, num_of_neighbours, report_failure=True):
    # Obtain the neighbouring pixels
    # This may throw an IndexError if a constructed circle overlaps with the boundary of an image
    neighbours = list()
    try:
        neighbours = _lbp_get_neighbours(image, row, col, radius, num_of_neighbours)
    except IndexError as e:
        if report_failure:
            print("Parameters row:", row, "col:", col, "Unable to construct circle. Please select different parameters.")
        raise e

    # Set the threshold
    threshold = image[row][col]
    # The result of the LBP comparison is the sum of the iterations
    result = 0
    for n in range(len(neighbours)):
        # Determine how current neighbour compares to threshold/central pixel
        if neighbours[n] > threshold:
            # Update sum
            result = result + (2 ** n)

    return result


# Method to obtain the neighbours used in calculating the local binary pattern for a given pixel
def _lbp_get_neighbours(image, row, col, radius, num_of_neighbours):
    # Determine the points to calculate for a quarter of the circle
    quadrant_count = int(num_of_neighbours / 4)
    # The list of neighbours
    neighbours = list()

    # Add the adjacent points to the top, bottom, left and right of centre pixel
    neighbours.append(image[row + radius][col])
    neighbours.append(image[row - radius][col])
    neighbours.append(image[row][col + radius])
    neighbours.append(image[row][col - radius])

    # Quadrant count would be one less because 1 point per quadrant has already been calculated
    quadrant_count = quadrant_count - 1
    # There are still neighbours to add
    if quadrant_count > 0:
        # The interval to gradually move along the x axis when calculating points
        x_interval = radius / (quadrant_count + 1)

        # Calculate remaining points
        for q in range(quadrant_count):
            # Given how many iterations, calculate delta in x position
            x_delta = (q + 1) * x_interval
            # Calculate delta in y position
            # Pythagoras' theorem: x2 + y2 = r2
            y_delta = math.sqrt((radius ** 2) - (x_delta ** 2))
            # Calculate new x and y coordinates
            x = col + x_delta
            y = row + y_delta
            # Add the element this point overlaps with to the neighbours list
            neighbours.append(image[round(y)][round(x)])

            # Cover the three other quadrants
            # Add the same point on the opposite side of the circle
            opposite_x = col - x_delta
            opposite_y = row - y_delta
            neighbours.append(image[round(opposite_y)][round(opposite_x)])
            # Add the same point on the opposite side of the x-axis of the circle
            neighbours.append(image[round(y)][round(opposite_x)])
            # Add the same point on the opposite side of the y-axis of the circle
            neighbours.append(image[round(opposite_y)][round(x)])

    # Report if neighbours list is different than what was expected
    if len(neighbours) != num_of_neighbours:
        raise RuntimeWarning("Requested", num_of_neighbours, "neighbours; returned", len(neighbours))
    return neighbours


# Method to obtain the most frequent LBP code for an image
def frequent_lbp(image, radius, num_of_neighbours):
    # Initialise all counts to 0: 256 possible values
    counts = [0] * 256
    for h in range(0, size):
        for w in range(0, size):
            lbp_code = 0
            # Skip iterations where the lbp cannot be found (i.e. edges of image)
            try:
                lbp_code = lbp(image, h, w, radius, num_of_neighbours, False)
            except IndexError:
                continue
            # Increment count for value
            counts[lbp_code] = counts[lbp_code] + 1
    # Determine most frequent result
    current_max_lbp = 0
    current_max_count = 0
    for e in range(256):
        if counts[e] > current_max_count:
            current_max_count = counts[e]
            current_max_lbp = e
    return current_max_lbp


# Read the four folders of images
print("Processing train and test instances")
count = 0
for filename in os.listdir(train_path + face_path):
    construct_instance(os.path.join(train_path + face_path, filename), 1, _add_train)
    count = count + 1
print("Processed", count, "class=1 (face) training instances")

count = 0
for filename in os.listdir(train_path + non_face_path):
    construct_instance(os.path.join(train_path + non_face_path, filename), 0, _add_train)
    count = count + 1
print("Processed", count, "class=0 (non-face) training instances")

count = 0
for filename in os.listdir(test_path + face_path):
    construct_instance(os.path.join(test_path + face_path, filename), 1, _add_test)
    count = count + 1
print("Processed", count, "class=1 (face) test instances")

count = 0
for filename in os.listdir(test_path + non_face_path):
    construct_instance(os.path.join(test_path + non_face_path, filename), 0, _add_test)
    count = count + 1
print("Processed", count, "class=0 (non-face) test instances")

# Write train-test data to csv files
with open("2-2-train.csv", "w+", newline='') as train_file:
    wr = csv.writer(train_file)
    for t in range(len(train)):
        wr.writerow(train[t])

with open("2-2-test.csv", "w+", newline='') as test_file:
    wr = csv.writer(test_file)
    for t in range(len(test)):
        wr.writerow(test[t])
print("Exported train-test data to CSV")

# Run the Naive Bayes classifier and report final results
classifier = GaussianNB()
classifier.fit(train_features, train_classes)
train_predicted = classifier.predict(train_features)
test_predicted = classifier.predict(test_features)
train_incorrect = (train_classes != train_predicted).sum()
test_incorrect = (test_classes != test_predicted).sum()
train_accuracy = ((len(train) - train_incorrect) / len(train)) * 100
test_accuracy = ((len(test) - test_incorrect) / len(test)) * 100
print("Training Accuracy:", "{:.2f}".format(train_accuracy) + "%")
print("Test Accuracy:", "{:.2f}".format(test_accuracy) + "%")

# ROC curve for classifier using only training data
# metrics.plot_roc_curve(classifier, test_features, test_classes)
# plt.show()

# ROC curve for classifier using all the data
# total_features = list(train_features) + list(test_features)
# total_classes = list(train_classes) + list(test_classes)
# classifier.fit(total_features, total_classes)
# total_predicted = classifier.predict(total_features)
# metrics.plot_roc_curve(classifier, total_features, total_classes)
# plt.show()
