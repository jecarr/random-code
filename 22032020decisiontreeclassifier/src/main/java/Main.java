import processing.Classifier;
import processing.InvalidDataException;

import java.io.IOException;

/**
 * The Main class to run Classifier.
 */
public class Main {

    /**
     * The main method.
     *
     * @param args Expecting two file paths: the first being a file path to a training
     *             set; the second being a file path to a test set.
     * @throws IOException when an incorrect file path has been supplied.
     * @throws InvalidDataException when the supplied files are found but could not be parsed.
     */
    public static void main(String[] args) throws IOException, InvalidDataException {

        // Read the supplied file paths: if we don't have two, then throw an Exception
        if(args.length != 2 || args[0] == null || args[1] == null) {
            Main.exit();
            return;
        }

        Classifier c;

        try {
            // Set up our Classifier with the raw training and test data
            c = new Classifier(args[0], args[1]);
        } catch(IOException | NumberFormatException | InvalidDataException e) {
            Main.exit();
            throw e;
        }

        // Classify test set
        System.out.println();
        System.out.println("Classifying test data");
        c.classifyTestSet();
    }

    /**
     * Method to inform the user the Main program is stopping.
     */
    private static void exit() {
        System.out.println("Incorrect argument(s) supplied");
        System.out.println("Please see readme.txt for more info");
    }
}