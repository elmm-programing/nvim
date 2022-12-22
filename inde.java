/**
 * inde
 */
public class inde {
	private static final String HELLO_WORLD = "Hello World";
	private static String helloWorld;

	/**
	 * @param args
	 */
	public static void main(String[] args){
		helloWorld = HELLO_WORLD;
		System.out.println(helloWorld);
	}

	

	public static String getHelloWorld() {
		return helloWorld;
	}

	public static void setHelloWorld(String helloWorld) {
		inde.helloWorld = helloWorld;
	}

	@Override
	public String toString() {
		return "inde []";
	}

}


