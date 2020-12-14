package processing;

import java.util.*;

/**
 * Class to represent a datum in test or training data.
 */
public class Patient {

    /** The list of attributes for this Patient instance */
    private Map<String, Boolean> attributes;
    /** The labelled class of this Patient */
    private String className;
    /** The number of attributes expected for a Patient */
    private static final int ATTRIBUTES_COUNT = 16;
    /** The keys for the different attributes expected for a Patient */
    public static final String LIVE_CLASS_KEY = "live";
    public static final String DIE_CLASS_KEY = "die";
    public static final String AGE_KEY = "AGE";
    public static final String IS_FEMALE_KEY = "FEMALE";
    public static final String STEROID_KEY = "STEROID";
    public static final String ANTIVIRAL_KEY = "ANTIVIRALS";
    public static final String FATIGUE_KEY = "FATIGUE";
    public static final String MALAISE_KEY = "MALAISE";
    public static final String ANOREXIA_KEY = "ANOREXIA";
    public static final String BIG_LIVER_KEY = "BIGLIVER";
    public static final String FIRM_LIVER_KEY = "FIRMLIVER";
    public static final String SPLEEN_PALPABLE_KEY = "SPLEENPALPABLE";
    public static final String SPIDERS_KEY = "SPIDERS";
    public static final String ASCITES_KEY = "ASCITES";
    public static final String VARICES_KEY = "VARICES";
    public static final String BILIRUBIN_KEY = "BILIRUBIN";
    public static final String SGOT_KEY = "SGOT";
    public static final String HISTOLOGY_KEY = "HISTOLOGY";

    /**
     * Constructor for a Patient instance.
     *
     * @param data A space-separated String with the attributes and class value for this Patient.
     * @throws InvalidDataException if data is not in the expected format.
     */
    public Patient(String data) throws InvalidDataException {

        // See how many attributes we have from the parameter data
        String[] allAttr = data.split(" ");
        // If it does not total the number of expected attributes plus 1 (for the class number) then this is invalid
        if(allAttr.length != ATTRIBUTES_COUNT + 1) {
            throw new InvalidDataException("The line\n" + data + "\nis not in the expected format");
        }

        // Else for the attributes...
        List<String> rawAttr = new ArrayList<>(Arrays.asList(allAttr));
        attributes = new HashMap<String, Boolean>();
        // Get the first element and set as the class number
        className = rawAttr.remove(0);
        List<String> attrNames = getAttributeNames();

        // and iterate through the rest, parse the values as booleans and add them to the attributes map
        for (int i = 0; i < attrNames.size(); i++) {
            attributes.put(attrNames.get(i), Boolean.parseBoolean(rawAttr.get(i)));
        }
    }

    /** Getter for the attributes map */
    public Map<String, Boolean> getAttributes() {
        return attributes;
    }

    /** Getter for a single attribute */
    public boolean getAttribute(String attribute) {
        return attributes.get(attribute);
    }

    /** Static method to return the attribute names of a Patient instance */
    public static List<String> getAttributeNames() {
        return new ArrayList<>(Arrays.asList(AGE_KEY, IS_FEMALE_KEY, STEROID_KEY, ANTIVIRAL_KEY, FATIGUE_KEY,
                MALAISE_KEY, ANOREXIA_KEY, BIG_LIVER_KEY, FIRM_LIVER_KEY, SPLEEN_PALPABLE_KEY, SPIDERS_KEY,
                ASCITES_KEY, VARICES_KEY, BILIRUBIN_KEY, SGOT_KEY, HISTOLOGY_KEY));
    }

    /** Static method to return the class types of a Patient instance */
    public static List<String> getClassValues() {
        return Arrays.asList(LIVE_CLASS_KEY, DIE_CLASS_KEY);
    }

    /** Getter for the className */
    public String getClassName() {
        return className;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Patient patient = (Patient) o;
        return Objects.equals(attributes, patient.attributes) &&
                Objects.equals(className, patient.className);
    }

    @Override
    public int hashCode() {
        return Objects.hash(attributes, className);
    }
}
