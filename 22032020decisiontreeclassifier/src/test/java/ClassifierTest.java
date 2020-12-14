import java.io.IOException;
import java.util.ArrayList;
import java.util.Map;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import processing.Classifier;
import processing.InvalidDataException;
import processing.Patient;

/**
 * A test class to check the Classifier class parses input files correctly.
 * Edit variables TEST_DATA_URL and TRAINING_DATA_URL for file paths.
 * Edit expected lines for expected entries if different files are used.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class ClassifierTest {

    private static final String TEST_DATA_URL = "resources\\hepatitis-test";
    private static final String TRAINING_DATA_URL = "resources\\hepatitis-training";
    private static final String INVALID_DATA_URL = "this_isn-t_a_file.txt";
    private static final String TRAINING_DATA = "Training Data";
    private static final String TEST_DATA = "Test Data";
    private ArrayList<Patient> trainingData;
    private ArrayList<Patient> testData;

    @BeforeAll
    public void setup() {
        trainingData = callGetData(TRAINING_DATA_URL, TRAINING_DATA);
        testData = callGetData(TEST_DATA_URL, TEST_DATA);
    }

    @Test
    public void testTrainingCorrectEntries() {
        Assertions.assertEquals(112, trainingData.size(), "Incorrect number of entries for " + TRAINING_DATA);
    }

    @Test
    public void testTestCorrectEntries() {
        Assertions.assertEquals(25, testData.size(), "Incorrect number of entries for " + TEST_DATA);
    }

    @Test
    public void testTrainingFirstEntry() {
        String firstEntry = "live false false false true false false false true false true true true true true true false";
        testEntry(trainingData, 0, firstEntry, TRAINING_DATA);

    }

    @Test
    public void testTrainingMidEntry() {
        String midEntry = "live true false true true true true true true true true true true true true false true";
        testEntry(trainingData, 39, midEntry, TRAINING_DATA);

    }

    @Test
    public void testTrainingLastEntry() {
        String lastEntry = "live true false true true true true true true true true true true true true false false";
        testEntry(trainingData, trainingData.size()-1, lastEntry, TRAINING_DATA);
    }

    @Test
    public void testTestDataFirstEntry() {
        String firstEntry = "live true true false true false true true true true false false true false true false true";
        testEntry(testData, 0, firstEntry, TEST_DATA);

    }

    @Test
    public void testTestDataMidEntry() {
        String midEntry = "live false false true true false true true true true true true true true false false false";
        testEntry(testData, 12, midEntry, TEST_DATA);

    }

    @Test
    public void testTestDataLastEntry() {
        String lastEntry = "live true false false true false true true true true true true true true false false false";
        testEntry(testData, testData.size()-1, lastEntry, TEST_DATA);
    }

    public void testEntry(ArrayList<Patient> data, int entryIndexToTest, String expectedAttrLine, String errorInfo) {
        Patient elem = data.get(entryIndexToTest);
        Map<String, Boolean> attr = elem.getAttributes();
        String className = elem.getClassName();

        String[] expectedAttr = expectedAttrLine.split(" ");

        Assertions.assertEquals(expectedAttr[0], className,
                "Incorrect Class Number read for " + errorInfo + "; entry " + entryIndexToTest);
        Assertions.assertEquals(expectedAttr[1], "" + attr.get(Patient.AGE_KEY), Patient.AGE_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[2], "" + attr.get(Patient.IS_FEMALE_KEY), Patient.IS_FEMALE_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[3], "" + attr.get(Patient.STEROID_KEY), Patient.STEROID_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[4], "" + attr.get(Patient.ANTIVIRAL_KEY), Patient.ANTIVIRAL_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[5], "" + attr.get(Patient.FATIGUE_KEY), Patient.FATIGUE_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[6], "" + attr.get(Patient.MALAISE_KEY), Patient.MALAISE_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[7], "" + attr.get(Patient.ANOREXIA_KEY), Patient.ANOREXIA_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[8], "" + attr.get(Patient.BIG_LIVER_KEY), Patient.BIG_LIVER_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[9], "" + attr.get(Patient.FIRM_LIVER_KEY), Patient.FIRM_LIVER_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[10], "" + attr.get(Patient.SPLEEN_PALPABLE_KEY), Patient.SPLEEN_PALPABLE_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[11], "" + attr.get(Patient.SPIDERS_KEY), Patient.SPIDERS_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[12], "" + attr.get(Patient.ASCITES_KEY), Patient.ASCITES_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[13], "" + attr.get(Patient.VARICES_KEY), Patient.VARICES_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[14], "" + attr.get(Patient.BILIRUBIN_KEY), Patient.BILIRUBIN_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[15], "" + attr.get(Patient.SGOT_KEY), Patient.SGOT_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
        Assertions.assertEquals(expectedAttr[16], "" + attr.get(Patient.HISTOLOGY_KEY), Patient.HISTOLOGY_KEY +
                " incorrect for entry " + entryIndexToTest + " read from " + errorInfo);
    }

    public ArrayList<Patient> callGetData(String url, String errorPrefix) {
        ArrayList<Patient> data = new ArrayList<>();
        try {
            data = Classifier.getData(url);
        } catch (IOException | InvalidDataException e) {
            Assertions.fail(errorPrefix + " should have been read properly");
        }
        return data;
    }

    @Test
    void testIncorrectFile() {
        Assertions.assertThrows(IOException.class, () -> {
            Classifier.getData(INVALID_DATA_URL);
        });
    }
}