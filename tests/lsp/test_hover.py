import pytest
import pytest_asyncio
from lsprotocol import types as lsp
from testlib import LanguageClient, open_file
from dataclasses import dataclass
from typing import Callable, List

async def hover(client: LanguageClient, file_uri: str, pos: lsp.Position):
    """
    Trigger a hover in the given file at the given position
    """
    results = await client.text_document_hover_async(
        params=lsp.HoverParams(
            text_document=lsp.TextDocumentIdentifier(file_uri),
            position=pos,
        )
    )
    return results

@dataclass
class HoverTest:
    file: str
    position: lsp.Position
    checks: Callable[[lsp.Hover], List[bool]]


@pytest.mark.asyncio
async def test_hover_on_option(client: LanguageClient):
    """
    Test that hovering over an option shows the right thing™
    """
    test_file = 'template/projectxx.ncl'
    test_file_content = """
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression & organist.tools.direnv
& {
    Schema,
    config | Schema = {
        files."foo.ncl".content = "1",

        shells = organist.shells.Bash,
    },
}
| organist.modules.T
    """
    test_uri = open_file(client, test_file, test_file_content)

    tests = [
        HoverTest(
            file=test_uri,
            position=lsp.Position(line=8, character=11), # `files`
            checks= lambda hover_info: [
                lsp.MarkedString_Type1(language='nickel', value='Files') in hover_info.contents,
                # Test that the contents contain a plain string (the documentation), and that it's non empty
                next(content for content in hover_info.contents if type(content) is str) != "",
            ]
        ),
        HoverTest(
            file=test_uri,
            position=lsp.Position(line=8, character=28), # `content`
            checks= lambda hover_info: [
                lsp.MarkedString_Type1(language='nickel', value='nix.derivation.NullOr nix.nix_string.NixString') in hover_info.contents,
                # Test that the contents contain a plain string (the documentation), and that it's non empty
                next(content for content in hover_info.contents if type(content) is str) != "",
            ]
        ),
        HoverTest(
            file=test_uri,
            position=lsp.Position(line=10, character=11), # `shells( =)`
            checks= lambda hover_info: [
                lsp.MarkedString_Type1(language='nickel', value='OrganistShells') in hover_info.contents,
                # Test that the contents contain a plain string (the documentation), and that it's non empty
                next(content for content in hover_info.contents if type(content) is str) != "",
            ]
        ),
    ]

    for test in tests:
        hover_info = await hover(
            client,
            test.file,
            test.position,
        )
        print(hover_info.contents)
        for check in test.checks(hover_info):
            assert check


