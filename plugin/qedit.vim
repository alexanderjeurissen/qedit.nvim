if !has('nvim-0.5')
    echohl ErrorMsg | echo 'qedit.nvim failed to initialize, RTFM.' | echohl None
    finish
endif

augroup QEDIT
  autocmd!
  autocmd BufWinEnter quickfix :lua require('qedit').attach()
  autocmd BufWriteCmd *.quickfix_edit :lua require('qedit').write()
augroup END
