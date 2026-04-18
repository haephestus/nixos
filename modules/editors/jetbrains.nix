{ pkgs, ... }:

{
  # ── JetBrains IDEs ────────────────────────────────────────────────────────
  # Uncomment whichever IDEs you want. allowUnfree is already set in home.nix.
  home.packages = with pkgs; [
    # === Free ===
    jetbrains.idea-community # IntelliJ IDEA Community
    # jetbrains.pycharm-community  # PyCharm Community
    # jetbrains.rider-free         # Rider (free as of 2025)

    # === Unfree (requires nixpkgs.config.allowUnfree = true) ===
    # jetbrains.idea-ultimate
    # jetbrains.pycharm-professional
    # jetbrains.clion
    # jetbrains.webstorm
    # jetbrains.goland
    # jetbrains.rust-rover
    # jetbrains.datagrip
    # jetbrains.phpstorm
    # jetbrains.ruby-mine
  ];

  # ── shared.vim ────────────────────────────────────────────────────────────
  # Sourced by BOTH init.lua and IdeaVim.
  # Keep it pure vimscript — no Lua, no Neovim-only APIs, no plugin calls.
  #
  # In your init.lua add this line:
  #   vim.cmd('source ~/.config/nvim/shared.vim')
  home.file.".config/nvim/shared.vim".text = ''
    " ── Options ───────────────────────────────────────────────────────────────
    set number
    set relativenumber
    set scrolloff=8
    set sidescrolloff=8
    set incsearch
    set hlsearch
    set ignorecase
    set smartcase
    set visualbell
    set noerrorbells
    set history=1000
    set clipboard+=unnamed

    " ── Leader ────────────────────────────────────────────────────────────────
    let mapleader = " "
    let maplocalleader = ","

    " ── Navigation ────────────────────────────────────────────────────────────
    " Centre cursor after search jumps
    nnoremap n nzz
    nnoremap N Nzz

    " Centre cursor after Ctrl-d / Ctrl-u
    nnoremap <C-d> <C-d>zz
    nnoremap <C-u> <C-u>zz

    " Keep selection after indent
    vnoremap < <gv
    vnoremap > >gv

    " Clear search highlight
    nnoremap <Esc> :noh<CR>

    " Move selected lines up/down
    vnoremap J :m '>+1<CR>gv=gv
    vnoremap K :m '<-2<CR>gv=gv

    " ── Splits ────────────────────────────────────────────────────────────────
    nnoremap <C-h> <C-w>h
    nnoremap <C-l> <C-w>l
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k

    " ── Editing ───────────────────────────────────────────────────────────────
    " Quick save
    nnoremap <leader>w :w<CR>

    " Delete without yanking into default register
    nnoremap <leader>d "_d
    vnoremap <leader>d "_d

    " Paste without overwriting register
    vnoremap <leader>p "_dP
  '';

  # ── IdeaVim configuration ─────────────────────────────────────────────────
  # IdeaVim must be installed from the JetBrains Plugin Marketplace first:
  #   Settings → Plugins → Marketplace → search "IdeaVim" → Install
  #
  # shared.vim is symlinked into the Nix store by Home Manager.
  # IdeaVim follows symlinks so `source` works transparently.
  home.file.".ideavimrc".text = ''
    " ── Source shared Neovim / IdeaVim config ─────────────────────────────────
    source ~/.config/nvim/shared.vim

    " ── IdeaVim-only clipboard ────────────────────────────────────────────────
    " ideaput makes paste respect IDE formatting and auto-imports
    set clipboard+=ideaput

    " ── IdeaVim extensions ────────────────────────────────────────────────────
    set surround            " cs, ds, ys  (vim-surround)
    set commentary          " gc          (vim-commentary)
    set argtextobj          " aa / ia     argument text objects
    set textobj-entire      " ae / ie     entire buffer text objects
    set ReplaceWithRegister
    set exchange            " cx          exchange two regions
    set highlightedyank     " briefly highlight yanked text
    set which-key           " show key binding hints
    set NERDTree            " :NERDTree   file explorer
    set multiple-cursors    " <A-n>       multiple cursors

    " ── Which-key ─────────────────────────────────────────────────────────────
    set timeoutlen=300
    let g:WhichKey_ShowVimActions = "true"

    " ── Go to ─────────────────────────────────────────────────────────────────
    map <leader>d  <Action>(GotoDeclaration)
    map <leader>D  <Action>(GotoTypeDeclaration)
    map <leader>i  <Action>(GotoImplementation)
    map <leader>u  <Action>(FindUsages)
    map <leader>s  <Action>(GotoSuperMethod)

    " ── File search ───────────────────────────────────────────────────────────
    map <leader>f  <Action>(GotoFile)
    map <leader>e  <Action>(RecentFiles)
    map <leader>o  <Action>(GotoClass)
    map <leader>a  <Action>(GotoAction)
    map <leader>/  <Action>(FindInPath)
    map <leader>S  <Action>(GotoSymbol)

    " ── Refactoring ───────────────────────────────────────────────────────────
    map <leader>r  <Action>(RenameElement)
    map <leader>R  <Action>(Refactorings.QuickListPopupAction)
    map <leader>=  <Action>(ReformatCode)
    map <leader>O  <Action>(OptimizeImports)
    map <leader>c  <Action>(ShowIntentionActions)

    " ── Folding ───────────────────────────────────────────────────────────────
    map za         <Action>(ExpandCollapseToggleAction)
    map zM         <Action>(CollapseAllRegions)
    map zR         <Action>(ExpandAllRegions)

    " ── Build / Run / Debug ───────────────────────────────────────────────────
    map <leader>bb <Action>(CompileProject)
    map <leader>br <Action>(Run)
    map <leader>bd <Action>(Debug)
    map <leader>bs <Action>(Stop)
    map <leader>B  <Action>(ToggleLineBreakpoint)
    map <leader>DB <Action>(ViewBreakpoints)

    " ── Tool windows ──────────────────────────────────────────────────────────
    map <leader>tp <Action>(ActivateProjectToolWindow)
    map <leader>ts <Action>(ActivateStructureToolWindow)
    map <leader>tg <Action>(ActivateVersionControlToolWindow)
    map <leader>tt <Action>(ActivateTerminalToolWindow)
    map <leader>tm <Action>(ActivateMavenToolWindow)
    map <leader>tb <Action>(ActivateBuildToolWindow)

    " ── Splits & tabs ─────────────────────────────────────────────────────────
    map <leader>wv <Action>(SplitVertically)
    map <leader>wh <Action>(SplitHorizontally)
    map <leader>wc <Action>(CloseContent)
    map <leader>wm <Action>(MoveEditorToOppositeTabGroup)
    map <leader>]  <Action>(NextTab)
    map <leader>[  <Action>(PreviousTab)

    " ── Git ───────────────────────────────────────────────────────────────────
    map <leader>gc <Action>(CheckinProject)
    map <leader>gp <Action>(Vcs.Push)
    map <leader>gu <Action>(Vcs.UpdateProject)
    map <leader>gl <Action>(Vcs.Show.Log)
    map <leader>gb <Action>(Annotate)
    map <leader>gr <Action>(Vcs.RollbackChangedLines)

    " ── Misc ──────────────────────────────────────────────────────────────────
    map <C-p>      <Action>(ParameterInfo)
    map <leader>x  <Action>(CloseActiveTab)
    map <leader>z  <Action>(ToggleDistractionFreeMode)
  '';
}
