import Testing
import KeySwitchCore

@Suite struct CaseCyclerTests {
    @Test(arguments: [
        ("hello", "Hello"), ("Hello", "HELLO"), ("HELLO", "hello"),
        ("привет", "Привет"), ("hello world", "Hello world"), ("Hello world", "HELLO WORLD"),
        ("hELLO", "Hello"), ("пРИВЕТ мИР", "Привет Мир"), ("heLLo", "hello"),
        ("a", "A"), ("A", "a"), ("(hello)", "(Hello)"), ("123", "123"), ("", ""),
    ])
    func next(_ text: String, _ expected: String) {
        #expect(CaseCycler.next(text) == expected)
    }
}
