import testlib
import asyncio
import pytest
import pytest_asyncio
from lsprotocol import types as lsp

@pytest_asyncio.fixture
async def client():
    # Setup
    client = testlib.LanguageClient()
    await client.start_io("nls")
    response = await client.initialize_async(
            lsp.InitializeParams(
                capabilities=lsp.ClientCapabilities(),
                root_uri="."
            )
        )
    assert response is not None
    client.initialized(lsp.InitializedParams())
    return client

