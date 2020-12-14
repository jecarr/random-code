package processing;

/**
 * An Exception thrown when data appears to be invalid.
 */
public class InvalidDataException extends Throwable {

    /**
     * Constructor for this Exception.
     *
     * @param message The error message.
     */
    public InvalidDataException(String message) {
        super(message);
    }
}