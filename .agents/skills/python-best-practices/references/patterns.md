# Python patterns

Code examples for each rule in `SKILL.md`, plus a curated design-pattern subset. Design-pattern notes lean on [faif/python-patterns](https://github.com/faif/python-patterns): prefer the Pythonic substitute, and skip patterns the language already covers.

## `NewType` brands

```python
from typing import NewType

UserId = NewType("UserId", str)

def parse_user_id(raw: str) -> UserId:
    if not raw:
        raise ValueError("empty user id")
    return UserId(raw)

def focus_user(user_id: UserId) -> None:
    ...
```

Validate at the boundary; downstream code takes `UserId`, not `str`.

## Discriminated unions

If a bug forces "can this combination happen?", the type is too loose.

```python
from dataclasses import dataclass
from typing import Literal, assert_never

@dataclass(frozen=True)
class Loading:
    kind: Literal["loading"] = "loading"

@dataclass(frozen=True)
class Ready:
    kind: Literal["ready"]
    body: str

@dataclass(frozen=True)
class Failed:
    kind: Literal["error"]
    message: str

DiffState = Loading | Ready | Failed

def render(state: DiffState) -> str:
    match state:
        case Loading():
            return "..."
        case Ready(body=body):
            return body
        case Failed(message=message):
            return message
        case _ as unreachable:
            assert_never(unreachable)
```

## `Protocol` over ABC

```python
from typing import Protocol

class Localizer(Protocol):
    def localize(self, msg: str) -> str: ...

def greet(localizer: Localizer, name: str) -> str:
    return localizer.localize(f"hello {name}")
```

Duck-typed call sites stay typed without a shared base class.

## `object` over `Any`

```python
# Don't
def handle(payload: Any) -> str:
    return payload["name"].upper()

# Do
def handle(payload: object) -> str:
    if not isinstance(payload, dict):
        raise TypeError("expected object")
    name = payload.get("name")
    if not isinstance(name, str):
        raise TypeError("expected name: str")
    return name.upper()
```

Or parse once with a schema library and pass the resulting dataclass inward.

## Boundary validation

```python
def parse_user(data: object) -> User:
    if not isinstance(data, dict):
        raise ValueError("expected object")
    # validate required fields, then:
    return User(id=parse_user_id(data["id"]), name=str(data["name"]))
```

Validate where JSON/env/HTTP/DB enters. Trust `User` inside.

## Fail loud

```python
# Don't: hides a missing config
api_key = os.environ.get("API_KEY") or ""

# Do
api_key = os.environ["API_KEY"]  # KeyError is the signal
```

Soft defaults only for true domain optionals (middle name, optional avatar URL).

## Dataclass for data, functions for behavior

```python
@dataclass(frozen=True)
class Order:
    id: str
    cents: int

def total_cents(orders: list[Order]) -> int:
    return sum(o.cents for o in orders)
```

## `pathlib` and context managers

```python
from pathlib import Path

def read_text(path: Path) -> str:
    with path.open(encoding="utf-8") as f:
        return f.read()
```

## Async

```python
import asyncio

async def fetch_all(urls: list[str]) -> list[bytes]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [t.result() for t in tasks]
```

Don't call blocking I/O or `time.sleep` inside `async def`. Use async clients or `asyncio.to_thread` for unavoidable sync work. Put cleanup in `async with` / `finally` so cancellation still runs it.

## Curated design patterns

Reach for these only when a plain function, dict of callables, or module doesn't already do the job. Catalog inspiration: [faif/python-patterns](https://github.com/faif/python-patterns).

### Factory (as a function)

A function that picks an impl beats a Factory class hierarchy.

```python
def get_localizer(language: str = "English") -> Localizer:
    table: dict[str, type[Localizer]] = {
        "English": EnglishLocalizer,
        "Greek": GreekLocalizer,
    }
    return table.get(language, EnglishLocalizer)()
```

### Strategy (as a callable)

```python
from collections.abc import Callable

def sort_names(names: list[str], key: Callable[[str], str] = str.lower) -> list[str]:
    return sorted(names, key=key)
```

Pass the algorithm in. No Strategy ABC unless you need a multi-method object.

### Decorator

Prefer `@contextmanager`, `functools.wraps`, or a small wrapper function over a Decorator class tree. Class decorators are fine when they clarify registration.

### Adapter / facade

Adapter: thin wrapper that translates one interface to another you own. Facade: one module/function that fronts a noisy subsystem. Keep both thin; don't grow a god object behind the name.

### Observer

Callbacks, `asyncio` events, or a tiny sync pub/sub beat a heavyweight Observer framework. Register/unregister explicitly; watch reference leaks.

### Dependency injection

Prefer constructor (or function-arg) injection so tests pass fakes without patching.

```python
class TimeDisplay:
    def __init__(self, time_provider: Callable[[], str]) -> None:
        self._time_provider = time_provider

    def as_html(self) -> str:
        return f"<span>{self._time_provider()}</span>"
```

Setter injection is a last resort: the object can exist in a half-ready state.

## Anti-patterns

Skip these even when a Java/C# guide lists them.

| Anti-pattern | Why | Prefer |
|--------------|-----|--------|
| Singleton class | Modules are already import-once singletons | Module-level object or explicit DI |
| God object | Untestable blob that knows everything | Small types + functions |
| Inheritance overuse | Brittle trees, unclear ownership | Composition, `Protocol`, delegation |
| Borg / shared-mutable-state singleton | Hidden coupling across instances | Explicit shared collaborator passed in |

When tempted to port a GoF class diagram into Python, ask whether a function, `Protocol`, or dict of callables already covers it. If yes, stop.
