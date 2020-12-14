package tree;

import processing.Patient;

/**
 * A class to represent a node with two branches in a tree.
 */
public class Node implements BaseNode {

    /** The left branch. */
    private BaseNode left;
    /** The right branch. */
    private BaseNode right;
    /** The attribute this node determines. */
    private String attribute;

    /**
     * Constructor for a Node.
     *
     * @param attr The attribute to set.
     * @param left The left branch to set.
     * @param right The right to set.
     */
    public Node(String attr, BaseNode left, BaseNode right) {
        attribute = attr;
        this.left = left;
        this.right = right;
    }

    @Override
    public String classify(Patient p) {
        boolean result = p.getAttribute(attribute);
        //System.out.println(attribute + "? " + result);
        if (result) return left.classify(p);
        else return right.classify(p);
    }

    @Override
    public void report(String indent) {
        System.out.format("%s%s = True:\n", indent, attribute);
        left.report(indent.replace("|", "_ ") + "|_ _ _ ");
        System.out.format("%s%s = False:\n", indent, attribute);
        right.report(indent.replace("|", "_ ") + "|_ _ _ ");
    }
}