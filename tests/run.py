"""Runs tests/test_*.lua under Lua 5.1 (lupa) with 42/media/lua/shared on package.path."""
import pathlib
import sys

from lupa import lua51

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHARED = (ROOT / "42/media/lua/shared").as_posix()

failed = 0
for test in sorted((ROOT / "tests").glob("test_*.lua")):
    lua = lua51.LuaRuntime()
    lua.execute(f'package.path = "{SHARED}/?.lua;" .. package.path')
    lua.execute(f'ROOT = "{ROOT.as_posix()}"')
    lua.execute("""
        PASSED, FAILED = 0, 0
        function check(ok, what)
            if ok then PASSED = PASSED + 1 else FAILED = FAILED + 1; print("FAIL: " .. what) end
        end
    """)
    lua.execute(test.read_text(encoding="utf-8"))
    passed, f = lua.eval("PASSED"), lua.eval("FAILED")
    print(f"{test.name}: {passed} passed, {f} failed")
    failed += f
sys.exit(1 if failed else 0)
