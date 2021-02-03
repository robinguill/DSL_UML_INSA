/*
 * generated by Xtext 2.24.0
 */
package org.xtext.example.mydsl.ui.quickfix;

import javax.swing.text.BadLocationException;

import org.eclipse.xtext.diagnostics.Diagnostic;
import org.eclipse.xtext.ui.editor.model.IXtextDocument;
import org.eclipse.xtext.ui.editor.model.edit.IModification;
import org.eclipse.xtext.ui.editor.model.edit.IModificationContext;
import org.eclipse.xtext.ui.editor.quickfix.DefaultQuickfixProvider;
import org.eclipse.xtext.ui.editor.quickfix.Fix;
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor;
import org.eclipse.xtext.validation.Issue;
import org.xtext.example.mydsl.validation.UmlValidator;

/**
 * Custom quickfixes.
 *
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#quick-fixes
 */
public class UmlQuickfixProvider extends DefaultQuickfixProvider {

	@Fix(UmlValidator.INVALID_NAME)
	public void capitalizeName(final Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, "Capitalize name", "Capitalize the name.", "upcase.png", new IModification() {
			public void apply(IModificationContext context) throws BadLocationException {
				IXtextDocument xtextDocument = context.getXtextDocument();
				String firstLetter;
				try {
					firstLetter = xtextDocument.get(issue.getOffset(), 1);
					xtextDocument.replace(issue.getOffset(), 1, firstLetter.toUpperCase());
				} catch (org.eclipse.jface.text.BadLocationException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});
	}
	
	@Fix(UmlValidator.ENUM_VALUES_CAPITAL)
	public void capitalizeEnumConstantsName(final Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, "Capitalize name", "Capitalize the name.", "upcase.png", new IModification() {
			public void apply(IModificationContext context) throws BadLocationException {
				IXtextDocument xtextDocument = context.getXtextDocument();
				String word;
				try {
					word = xtextDocument.get(issue.getOffset(),issue.getLength());
					xtextDocument.replace(issue.getOffset(), issue.getLength(), word.toUpperCase());
				} catch (org.eclipse.jface.text.BadLocationException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});
	}
	
	@Fix(Diagnostic.SYNTAX_DIAGNOSTIC)
	public void generateClassContent(final Issue issue, IssueResolutionAcceptor acceptor) {
		String toAdd, title, description;
		int charToChange, offset;
		System.out.println(issue.getMessage());
		if(issue.getMessage().contains("mismatched input '}' expecting 'parameter'")) {
			toAdd =	""
					+ "attribute {\n"
					+ "}\n"
					+ "function {\n"
					+ "}"
					+ "";
			title = "Generate class content";
			description = "Generate attributes and functions container";
			charToChange = 0;
			offset = issue.getLength();
		}else if (issue.getMessage().equals("mismatched input '}' expecting 'function'")) {
			toAdd="\n function {\n"
					+ "}"
					+ "";
			title = "Generate function container";
			description = "Generate missing functions container";
			charToChange = 0;
			offset = issue.getLength() -1;
		}else if (issue.getMessage().contains("expecting '}'")) {
			toAdd="}";
			title = "Autocomplete";
			description = "";
			charToChange = 0;
			offset = issue.getLength();
		}else if (issue.getMessage().equals("extraneous input '-' expecting RULE_INT")) {
			toAdd="";
			title = "Use positive number";
			description="Suppress the '-' character";
			charToChange = 1;
			offset = 0;
		}
		else{
			toAdd = "";
			title = "No quickfix available for this problem";
			description = "";
			charToChange = 0;
			offset = issue.getLength();
		}
		
		
		acceptor.accept(issue, title, description, "", new IModification() {
			public void apply(IModificationContext context) throws BadLocationException {
				try {
				IXtextDocument xtextDocument= context.getXtextDocument();
					xtextDocument.replace(issue.getOffset() - offset, charToChange, toAdd);
				} catch (org.eclipse.jface.text.BadLocationException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});
	}
}