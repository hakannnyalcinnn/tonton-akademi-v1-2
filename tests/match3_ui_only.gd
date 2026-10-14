extends "res://tests/run_tests.gd"
## Resume only the UI portion after a diagnosed preflight assertion mismatch.
func run() -> void:
	await test_ui()
	await create_timer(.15).timeout
	print("MATCH3 UI ONLY: %d assertions, %d failures"%[checks,failures])
	quit(1 if failures else 0)
