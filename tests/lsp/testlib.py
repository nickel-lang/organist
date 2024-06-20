from pygls.lsp.client import BaseLanguageClient
from typing import Optional
import os
from lsprotocol import types as lsp

class LanguageClient(BaseLanguageClient):

    def __init__(self):
        super().__init__("organist-test-suite", "v1")
        self.diagnostics: Dict[str, List[types.Diagnostic]] = {}

        @self.feature(lsp.TEXT_DOCUMENT_PUBLISH_DIAGNOSTICS)
        def publish_diagnostics(
            client: LanguageClient, params: lsp.PublishDiagnosticsParams
        ):
            client.diagnostics[params.uri] = params.diagnostics

def open_file(client: LanguageClient, file_path: str, file_content: Optional[str] = None):
    """
    Open the given file in the LSP.

    If `file_content` is non `None`, then it will be used as the content sent to the LSP.
    Otherwise, the actual file content will be read from disk.
    """
    file_uri = f"file://{os.path.abspath(file_path)}"
    actual_file_content = file_content
    if file_content is None:
        with open(file_path) as content:
            actual_file_content = content.read()

    client.text_document_did_open(
        lsp.DidOpenTextDocumentParams(
            text_document=lsp.TextDocumentItem(
                uri=file_uri,
                language_id="nickel",
                version=1,
                text=actual_file_content
            )
        )
    )
    return file_uri

