package tree;

import processing.Patient;

/**
 * An interface to represent any type of Node in a tree.
 */
public interface BaseNode {

    /**
     * Given a Patient instance, this returns the class name of what this Node/tree determines the Patient should be.
     *
     * @param p The Patient instance to classify.
     * @return the class name of what Patient p has been determined to be.
     */
    public abstract String classify(Patient p);

    /**
     * A method to report on the current attributes of the BaseNode instance.
     *
     * @param indent The indentation used to report this BaseNode.
     */
    public abstract void report(String indent);
}