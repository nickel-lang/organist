import pytest
import pytest_asyncio
from lsprotocol import types as lsp
from testlib import LanguageClient, open_file

async def complete(client: LanguageClient, file_uri: str, pos: lsp.Position):
    """
    Trigger an autocompletion in the given file at the given position
    """
    results = await client.text_document_completion_async(
        params=lsp.CompletionParams(
            text_document=lsp.TextDocumentIdentifier(file_uri),
            position=pos,
        )
    )
    assert results is not None

    if isinstance(results, lsp.CompletionList):
        items = results.items
    else:
        items = results
    return items

@pytest.mark.asyncio
async def test_completion_at_toplevel(client):
    """
    Test that getting an autocompletion at toplevel shows the available fields
    """

    test_file = 'template/project.ncl'
    with open('../../templates/default/project.ncl') as template_file:
        test_file_content = template_file.read()

    test_uri = open_file(client, test_file, test_file_content)

    completion_items = await complete(
        client,
        test_uri,
        lsp.Position(line=12, character=0) # Empty line in the `config` record
    )

    labels = [item.label for item in completion_items]
    assert "files" in labels
    files_item = [item for item in completion_items if item.label == "files"][0]
    assert files_item.documentation.value != ""

@pytest.mark.asyncio
async def test_completion_sub_field(client: LanguageClient):
    """
    Test that completing on an option shows the available sub-options
    """
    test_file = 'template/projectxx.ncl'
    test_file_content = """
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression
& {
    Schema,
    config | Schema = {
      files.foo.c
    },
}
| organist.modules.T
    """
    test_uri = open_file(client, test_file, test_file_content)
    completion_items = await complete(
        client,
        test_uri,
        lsp.Position(line=8, character=17) # The `c` in `files.foo.c`
    )

    labels = [item.label for item in completion_items]
    assert "content" in labels
    content_item = [item for item in completion_items if item.label == "content"][0]
    assert content_item.documentation.value != ""

@pytest.mark.asyncio
async def test_completion_with_custom_module(client: LanguageClient):
    """
    Test that completing takes into account extra modules
    """
    test_file = 'template/projectxx.ncl'
    test_file_content = """
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression & organist.tools.direnv
& {
    Schema,
    config | Schema = {

    },
}
| organist.modules.T
    """
    test_uri = open_file(client, test_file, test_file_content)
    completion_items = await complete(
        client,
        test_uri,
        lsp.Position(line=8, character=0) # Empty line in the `config` record
    )

    labels = [item.label for item in completion_items]
    assert "direnv" in labels

    ## No documentation for direnv yet
    # content_item = [item for item in completion_items if item.label == "direnv"][0]
    # assert content_item.documentation.value != ""

@pytest.mark.asyncio
async def test_completion_organist_lib(client: LanguageClient):
    """
    Make sure that everything directly exported by the library has a documentation, and that the LSP can see it
    """

    test_file = 'template/projectxx.ncl'
    test_file_content = """
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.
    """

    test_uri = open_file(client, test_file, test_file_content)
    completion_items = await complete(
        client,
        test_uri,
        lsp.Position(line=4, character=9) # End ot the last line
    )
    assert completion_items is not []
    for item in completion_items:
        assert item.documentation is not None and item.documentation.value != ""
