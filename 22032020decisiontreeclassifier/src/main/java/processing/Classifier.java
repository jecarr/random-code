package processing;

import org.apache.commons.io.FileUtils;
import tree.BaseNode;
import tree.Node;
import tree.LeafNode;

import java.io.IOException;
import java.nio.charset.Charset;

import java.io.File;
import java.util.*;
import java.util.stream.Collectors;

/**
 * A class to classify instances of Patient.
 */
public class Classifier {

    /** The training set of data */
    private ArrayList<Patient> trainingData;
    /** The test set of data */
    private ArrayList<Patient> testData;
    /** The number of correct classifications */
    private int correctClassifications;
    /** The decision tree classifier */
    private BaseNode treeClassifier;
    /** Key for flagging instances where for an attribute, the attribute is true */
    private static final String ATTR_TRUE_KEY = "Attribute is True";
    /** Key for flagging instances where for an attribute, the attribute is true and the patient is flagged to live */
    private static final String ATTR_TRUE_LIVE_KEY = "True Instance; Class \"" + Patient.LIVE_CLASS_KEY + "\"";
    /** Key for flagging instances where for an attribute, the attribute is true and the patient is flagged to die */
    private static final String ATTR_TRUE_DIE_KEY = "True Instance; Class \"" + Patient.DIE_CLASS_KEY + "\"";
    /** Key for flagging instances where for an attribute, the attribute is false */
    private static final String ATTR_FALSE_KEY = "Attribute is False";
    /** Key for flagging instances where for an attribute, the attribute is false and the patient is flagged to live */
    private static final String ATTR_FALSE_LIVE_KEY = "False Instance; Class \"" + Patient.LIVE_CLASS_KEY + "\"";
    /** Key for flagging instances where for an attribute, the attribute is false and the patient is flagged to die */
    private static final String ATTR_FALSE_DIE_KEY = "False Instance; Class \"" + Patient.DIE_CLASS_KEY + "\"";
    /** Most probable class information for training data set */
    private MostProbableClass probableAcrossDataSet;

    /**
     * Constructor for a Classifier.
     *
     * @param trainingDataUrl The file path for the training data.
     * @param testDataUrl The file path for the test data.
     * @throws IOException if any file path is incorrect.
     * @throws InvalidDataException if any part of the data cannot be used to create a Patient instance.
     */
    public Classifier(String trainingDataUrl, String testDataUrl) throws IOException, InvalidDataException {
        trainingData = getData(trainingDataUrl);
        testData = getData(testDataUrl);
        probableAcrossDataSet = getMostProbableClass(trainingData, trainingData.size());
        treeClassifier = buildTree(new HashSet<>(trainingData), Patient.getAttributeNames());
        treeClassifier.report("");
    }

    /**
     * Classify the test set tied to this instance.
     */
    public void classifyTestSet() {

        correctClassifications = 0;
        int testDataSize = testData.size();

        // For each entry in the test data...
        for (int x = 0; x < testDataSize; x++) {

            Patient current = testData.get(x);
            String expectedClass = current.getClassName();

            // classify it...
            String determinedClass = treeClassifier.classify(current);
            if (expectedClass.equals(determinedClass)) correctClassifications++;

            //System.out.println("Entry " + (x + 1) + "; Class: " + determinedClass);
            // whilst comparing what the class should have been
            //System.out.println("EXPECTED Class: " + expectedClass);
        }
        System.out.println("Correct Classifications " + correctClassifications);
        System.out.println("Finished with accuracy " + getAccuracy(testDataSize));
    }

    /**
     * Method to calculate accuracy of classifications.
     *
     * @param dataSize Size of the data.
     * @return the calculated accuracy as a percentage.
     */
    public double getAccuracy(int dataSize) {
        return ( correctClassifications * 100 ) / (float) dataSize;
    }

    /**
     * Method to convert data files into a list of Patient instances.
     *
     * @param fileUrl The file path to the data.
     * @return a list of the data as Patient instances.
     * @throws IOException if the file path is incorrect.
     * @throws InvalidDataException if any part of the data cannot be used to create a Patient instance.
     */
    public static ArrayList<Patient> getData(String fileUrl) throws IOException, InvalidDataException {

        ArrayList<Patient> data = new ArrayList<>();
        File file = new File(fileUrl);

        List<String> readData = FileUtils.readLines(file, Charset.defaultCharset());
        // Remove headings in line 1
        readData.remove(0);

        // For each line, create and add to the list a new Patient Instance
        for(String datum : readData) {
            data.add(new Patient(datum));
        }

        return data;
    }

    /**
     * Method to build a decision tree based on a set of instances and a list of attributes.
     *
     * @param instances The instances to use to build the tree.
     * @param attributes The attributes to include in the tree.
     * @return a BaseNode instance which is the decision tree.
     * @throws InvalidDataException if invalid data is passed to a LeafNode constructor.
     */
    private BaseNode buildTree(Set<Patient> instances, List<String> attributes) throws InvalidDataException {
        // Following the algorithm...
        // If the set of instances is empty...
        if (instances.size() == 0) {
            // Return a leaf node with the most probable class
            return new LeafNode(probableAcrossDataSet.getClassName(), probableAcrossDataSet.getProbability());
        }

        // If the instances are pure, return a leaf node with this class and a probability of 1
        String pureClass = checkPurity(instances);
        if (pureClass != null) return new LeafNode(pureClass, 1);

        // If the attributes list is empty...
        if (attributes.size() == 0) {
            // Return a leaf node with most probable class of the instances in this node
            // This code does not cater for randomness if there is a tie between class counts
            MostProbableClass mostProbable = getMostProbableClass(instances, instances.size());
            return new LeafNode(mostProbable.getClassName(), mostProbable.getProbability());
        }
        else // find the best attribute
        {
            // Max weighted impurity would be a decimal, less than 0.25
            float bestWeightedImpurity = 1;
            // The three variables we need to determine
            String bestAttribute = "";
            Set<Patient> bestInstsTrue = new HashSet<>();
            Set<Patient> bestInstsFalse = new HashSet<>();

            // Loop through the attributes
            for (String attr : attributes) {
                // For this attribute, have the 'true' and 'false' instances ready
                ImpurityCheck impurities = prepareImpurityCheck(instances, attr);
                // and calculate the weighted impurity
                float weightedImpurity = impurities.getWeightedImpurity();

                // If this is the most pure attribute we have seen so far, set the three variables for this attribute
                if (weightedImpurity < bestWeightedImpurity) {
                    bestAttribute = attr;
                    bestInstsTrue = impurities.getTrueInstances();
                    bestInstsFalse = impurities.getFalseInstances();
                }
            }

            // Calculate the left and right branches for the tree and return the tree
            attributes.remove(bestAttribute);
            BaseNode left = buildTree(bestInstsTrue, attributes);
            BaseNode right = buildTree(bestInstsFalse, attributes);
            return new Node(bestAttribute, left, right);
        }
    }

    /**
     * Method to go through a data set for a given attribute and have the necessary numbers and lists ready to calculate
     * the impurity.
     *
     * @param data The data set to go through.
     * @param attribute The attribute we are going through the data set with.
     * @return An ImpurityCheck object with the true/false lists ready.
     */
    private ImpurityCheck prepareImpurityCheck(Set<Patient> data, String attribute) {

        // Lists to hold the instances where for attribute, they are true and false
        Set<Patient> trueInstances = new HashSet<>();
        Set<Patient> falseInstances = new HashSet<>();
        // The singular map to hold both the true and false instances (albeit separated)
        Map<String, Set<Patient>> splits = new HashMap<>();
        // A map to keep count of different permutations of the instance's attribute value and overall class
        Map<String, Integer> counts = new HashMap<>();
        // The counts to keep track of
        // Attribute is true, class is 'live'
        int trueInstsClassLiveCount = 0;
        // Attribute is true, class is 'die'
        int trueInstsClassDieCount = 0;
        // Attribute is false, class is 'live'
        int falseInstsClassLiveCount = 0;
        // Attribute is false, class is 'die'
        int falseInstsClassDieCount = 0;
        // For each instance in the data...
        for (Patient p : data) {
            // determine the attribute value
            boolean value = p.getAttribute(attribute);
            // and get the class value
            String className = p.getClassName();
            boolean isLive = Patient.LIVE_CLASS_KEY.equals(className);
            // Increment the appropriate count and add to appropriate list
            if (value) {
                trueInstances.add(p);
                if (isLive) trueInstsClassLiveCount++;
                else trueInstsClassDieCount++;
            }
            else {
                falseInstances.add(p);
                if (isLive) falseInstsClassLiveCount++;
                else falseInstsClassDieCount++;
            }
        }

        // Update maps as declared initially
        splits.put(ATTR_TRUE_KEY, trueInstances);
        splits.put(ATTR_FALSE_KEY, falseInstances);
        counts.put(ATTR_TRUE_LIVE_KEY, trueInstsClassLiveCount);
        counts.put(ATTR_TRUE_DIE_KEY, trueInstsClassDieCount);
        counts.put(ATTR_FALSE_LIVE_KEY, falseInstsClassLiveCount);
        counts.put(ATTR_FALSE_DIE_KEY, falseInstsClassDieCount);
        // return ImpurityCheck variable
        return new ImpurityCheck(splits, counts);
    }

    /**
     * Method to check the purity of a data set.
     *
     * @param data The data set to check.
     * @return the name of the class if data set is pure; else returns null.
     */
    private String checkPurity(Set<Patient> data) {

        if (data.size() == 0) return null;
        // Get first class value in the data set
        String currentClass = data.iterator().next().getClassName();
        String nextClass;

        // Keep looping through the data set
        for (Patient datum : data) {
            nextClass = datum.getClassName();
            // Until a different class has been retrieved: set is impure so return null
            if (!currentClass.equals(nextClass)) return null;
            currentClass = nextClass;
        }

        return currentClass;
    }

    /**
     * Given a data set, returns the most probable class.
     *
     * @param data The data to iterate through.
     * @param dataSize The size of the iterable data set.
     * @return an instance of MostProbableClass containing the class name and probability of most probable class.
     */
    private MostProbableClass getMostProbableClass(Iterable<Patient> data, int dataSize) {

        if (dataSize == 0) return new MostProbableClass("", 0);

        List<String> classes = Patient.getClassValues();
        // Variables to keep track of highest class count
        String mostFrequentClass = "";
        int highestCount = 0;
        // For all the classes possible...
        for (String cl : classes) {
            int count = 0;
            // and for each instance in the data
            for (Patient datum : data) {
                // Count how many instances are of that class
                boolean match = datum != null && datum.getClassName().equals(cl);
                if (match) count++;
            }
            // If this is our highest count so far, update the appropriate variables
            if (count > highestCount) {
                highestCount = count;
                mostFrequentClass = cl;
            }
        }
        return new MostProbableClass(mostFrequentClass, highestCount / (float) dataSize);
    }

    /**
     * Inner-class to store the most probable class information.
     */
    private class MostProbableClass {

        /** The name of the most probable class */
        private String className;
        /** The probability of this class */
        private float probability;

        /**
         * Constructor with both variables.
         *
         * @param cl The class name to store.
         * @param prob The probability to store.
         */
        public MostProbableClass(String cl, float prob) {
            className = cl;
            probability = prob;
        }

        /** Getter for className */
        public String getClassName() {
            return className;
        }

        /** Getter for probability */
        public float getProbability() {
            return probability;
        }
    }

    /**
     * Inner-class to store the information needed when calculating impurity in data.
     */
    private class ImpurityCheck {

        /** Map to keep track of instances where an attribute is true and false, separately */
        private Map<String, Integer> counts;
        /** Map to keep track of various counts/list sizes */
        private Map<String, Float> impurities;
        /** Map to keep track of different impurity values */
        private Map<String, Set<Patient>> splitSet;

        /**
         * Constructor for an ImpurityCheck instance.
         *
         * @param splits The map of the true-instances and false-instances
         * @param counts The map of the different counts/list sizes
         */
        public ImpurityCheck(Map<String, Set<Patient>> splits, Map<String, Integer> counts) {
            splitSet = splits;
            this.counts = counts;
            setImpurities();
        }

        /** Getter for true-instances set */
        public Set<Patient> getTrueInstances() {
            return splitSet.get(ATTR_TRUE_KEY);
        }

        /** Getter for false-instances set */
        public Set<Patient> getFalseInstances() {
            return splitSet.get(ATTR_FALSE_KEY);
        }

        /** Setter for impurities values */
        private void setImpurities() {
            impurities = new HashMap<>();
            impurities.put(ATTR_TRUE_KEY,
                calculateImpurity(counts.get(ATTR_TRUE_LIVE_KEY), counts.get(ATTR_TRUE_DIE_KEY)));
            impurities.put(ATTR_FALSE_KEY,
                calculateImpurity(counts.get(ATTR_FALSE_LIVE_KEY), counts.get(ATTR_FALSE_DIE_KEY)));
        }

        /**
         * Given two classes A and B, this method returns the impurity.
         *
         * @param classACount Count for class A instances.
         * @param classBCount Count for class B instances.
         * @return the calculated impurity.
         */
        private float calculateImpurity(int classACount, int classBCount) {
            if (classACount + classBCount == 0) return 0;
            return (classACount * classBCount) / (float) Math.pow(classACount + classBCount, 2);
        }

        /**
         * Given the data in this instance, this method returns the weighted impurity.
         *
         * @return the calculated weighted impurity for what is set on this instance.
         */
        public float getWeightedImpurity() {

            int trueTotal = splitSet.get(ATTR_TRUE_KEY).size();
            int falseTotal = splitSet.get(ATTR_FALSE_KEY).size();
            int total = trueTotal + falseTotal;

            if (total == 0) return 0;
            // Determine probabilities for use in final equation
            float trueProb = trueTotal / (float) total;
            float falseProb = falseTotal / (float) total;

            return ( trueProb * impurities.get(ATTR_TRUE_KEY) ) + ( falseProb * impurities.get(ATTR_FALSE_KEY) );
        }
    }
}