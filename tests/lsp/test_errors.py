import asyncio
import pytest
import pytest_asyncio
from lsprotocol import types as lsp
from testlib import LanguageClient, open_file
from dataclasses import dataclass
from typing import Callable, List

@pytest.mark.asyncio
async def test_bad_field_type(client: LanguageClient):
    """
    Test that a field with a bad type raises the right error
    """
    test_file = 'template/project.ncl'
    test_file_content = """
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
    Schema,
    config | Schema = {
        files."foo.ncl".content = true,
    },
}
& organist.OrganistExpression
| organist.modules.T
    """
    test_uri = open_file(client, test_file, test_file_content)

    await asyncio.sleep(1)

    assert client.diagnostics is not {}

    assert list(client.diagnostics.keys()) == [test_uri]
    assert len(client.diagnostics[test_uri]) >= 1
    first_diagnostic = client.diagnostics[test_uri][0]
    assert first_diagnostic.severity == lsp.DiagnosticSeverity.Error
    assert "content" in first_diagnostic.message
    # assert "true" in first_diagnostic.message


@pytest.mark.asyncio
async def test_bad_field_name(client: LanguageClient):
    """
    Test that a field with a bad name raises the right error
    """
    test_file = 'template/project.ncl'
    test_file_content = """
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
    Schema,
    config | Schema = {
        fies."foo.ncl".content = "foo",
    },
}
& organist.OrganistExpression
    """
    test_uri = open_file(client, test_file, test_file_content)

    await asyncio.sleep(1)

    assert client.diagnostics is not {}

    assert list(client.diagnostics.keys()) == [test_uri]
    assert len(client.diagnostics[test_uri]) >= 1
    first_diagnostic = client.diagnostics[test_uri][0]
    assert first_diagnostic.severity == lsp.DiagnosticSeverity.Error
    assert "extra field" in first_diagnostic.message
