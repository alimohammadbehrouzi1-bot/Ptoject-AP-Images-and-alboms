package ServiesFaz1;

public class IsValid {
    public static void validatePassword(String username, String password) throws Exception {
        boolean hasUpper = false;
        boolean hasLower = false;
        boolean hasDigit = false;
        if (password.length() >= 8) {
            if (!password.contains(username)) {
                for (char c : password.toCharArray()) {
                    if (Character.isUpperCase(c)) hasUpper = true;
                    else if (Character.isLowerCase(c)) hasLower = true;
                    else if (Character.isDigit(c)) hasDigit = true;
                }
                if (hasDigit && hasLower && hasUpper) {
                    return;
                } else throw new Exception("Password must contain uppercase, lowercase and digit.");
            }
            throw new Exception("Password must not contain username.");
        }
        throw new Exception("Password must be at least 8 characters.");
    }

    public void isValidEmail(){

    }

    public void isValidPassword(){

    }

    public void isValidPhoneNumber(){

    }
}
