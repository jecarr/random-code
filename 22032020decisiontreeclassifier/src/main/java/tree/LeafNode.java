package tree;

import processing.InvalidDataException;
import processing.Patient;

/**
 * A class to represent a leaf node in a tree.
 */
public class LeafNode implements BaseNode {

    /** The probability of the class being selected in the tree. */
    private float probability;
    /** The name of the class this leaf node represents. */
    private String className;

    /**
     * Constructor for a leaf node.
     *
     * @param className The class name to set on this leaf node.
     * @param prob The probability of the class to set.
     */
    public LeafNode(String className, float prob) throws InvalidDataException {
        this.className = className;
        if (prob < 0 || prob > 1) throw new InvalidDataException("Invalid Probability value: " + prob);
        probability = prob;
    }

    @Override
    public String classify(Patient p) {
        return className;
    }

    @Override
    public void report(String indent) {
        System.out.format("%sClass %s, probability = %.2f \n", indent, className, probability);
    }
}