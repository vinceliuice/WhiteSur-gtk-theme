(function () {
	var css = `
	@namespace url(http: //www.mozilla.org/keymaster/gatekeeper/there.is.only.xul);
	@namespace html url("http://www.w3.org/1999/xhtml");

	/* Colours - can't be read from chrome CSS. Setting on :root doesn't work. */
	:not(select):not(hbox) > scrollbar {
		--gnome-scrollbars-hover-bgcolor: rgba(192, 192, 192, 0.75);
		--gnome-scrollbars-hover-border-color: rgba(192, 192, 192, 0.75);
		--gnome-scrollbars-thumb-bgcolor: rgba(0, 0, 0, 0.32);
		--gnome-scrollbars-thumb-blend-mode: multiply;
		--gnome-scrollbars-thumb-outline: 1px solid rgba(255, 255, 255, 0.4);
		--gnome-scrollbars-thumb-hover-bgcolor: #75797a;
		--gnome-scrollbars-thumb-active-bgcolor: #4a90d9;
	}
	@media (prefers-color-scheme: dark) {
		:not(select):not(hbox) > scrollbar {
			--gnome-scrollbars-hover-bgcolor: rgba(29, 30, 31, 0.75);
			--gnome-scrollbars-hover-border-color: rgba(13, 17, 18, 0.75);
			--gnome-scrollbars-thumb-bgcolor: rgba(252, 254, 251, 0.58);
			--gnome-scrollbars-thumb-blend-mode: screen;
			--gnome-scrollbars-thumb-outline: 1px solid rgba(0, 0, 0, 0.4);
			--gnome-scrollbars-thumb-hover-bgcolor: #d4d5d4;
			--gnome-scrollbars-thumb-active-bgcolor: #15539e;
		}
	}

	/* All states */
	:not(select):not(hbox) > scrollbar {
		-moz-appearance: none !important;
		position: relative;
		box-sizing: border-box !important;
		background-color: transparent;
		background-image: none;
		z-index: 1;
		pointer-events: auto;
		width: auto !important;
		border-style: solid !important;
		display: flex !important;
		justify-content: flex-end;
		transition: all 0.1s linear;
	}
	scrollbar[root="true"] {
		z-index: 2147483647 !important;
	}
	.panel-subview-body > scrollbar[orient="vertical"] {
		width: 16px !important;
	}
	:not(select):not(hbox) > scrollbar[orient="vertical"] {
		border-width: 0 0 0 1px;
		-moz-margin-start: -13px;
	}
	:not(select):not(hbox) > scrollbar[orient="horizontal"] {
		border-width: 1px 0 0 0;
		margin-top: -13px;
	}
	:not(select):not(hbox) > scrollbar thumb {
		-moz-appearance: none !important;
		mix-blend-mode: var(--gnome-scrollbars-thumb-blend-mode);
		/* Make handle edge-grabbable */
		border: 3px solid transparent;
		background-clip: padding-box;
		border-radius: 6px;
	}
	:not(select):not(hbox) > scrollbar[orient="vertical"] thumb {
		min-height: 44px !important;
	}
	:not(select):not(hbox) > scrollbar[orient="horizontal"] thumb {
		min-width: 44px !important;
	}
	/* Unhovered */
	:not(select):not(hbox) > scrollbar {
		background-color: transparent;
		border-color: transparent;
	}
	:not(select):not(hbox) > scrollbar[orient="vertical"] {
		padding: 0 1px 0 5px;
		margin-right: -3px;
		width: 0px !important;
	}
	:not(select):not(hbox) > scrollbar[orient="horizontal"] {
		padding: 5px 0 1px 0;
		margin-bottom: -3px;
		height: 16px !important;
	}
	:not(select):not(hbox) > scrollbar thumb {
		background-color: var(--gnome-scrollbars-thumb-bgcolor);
		outline: var(--gnome-scrollbars-thumb-outline);
		outline-offset: -3px;
		-moz-outline-radius: 3px;
	}
	/* Hovered scrollbar */
	:not(select):not(hbox) > scrollbar:hover {
		background-color: var(--gnome-scrollbars-hover-bgcolor);
		border-color: var(--gnome-scrollbars-hover-border-color);
	}
	:not(select):not(hbox) > scrollbar:hover thumb {
		outline-width: 0;
	}
	:not(select):not(hbox) > scrollbar[orient="vertical"]:hover {
		padding: 0 1px 0 0;
		margin-right: -1px;
		width: 14px !important;
	}
	:not(select):not(hbox) > scrollbar[orient="horizontal"]:hover {
		padding: 0 0 1px 0;
		margin-bottom: -1px;
		height: 14px !important;
	}
	/* Hovered thumb */
	:not(select):not(hbox) > scrollbar:hover thumb:hover {
		background-color: var(--gnome-scrollbars-thumb-hover-bgcolor);
	}
	/* Grabbed thumb */
	:not(select):not(hbox) > scrollbar:hover thumb:active {
		background-color: var(--gnome-scrollbars-thumb-active-bgcolor);
		mix-blend-mode: normal;
	}
	`;
	
	var sss = Cc['@mozilla.org/content/style-sheet-service;1'].getService(Ci.nsIStyleSheetService);
	var uri = makeURI('data:text/css;charset=UTF=8,' + encodeURIComponent(css));    
	sss.loadAndRegisterSheet(uri, sss.AGENT_SHEET)
})();

