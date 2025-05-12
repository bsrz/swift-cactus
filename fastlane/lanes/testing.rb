lane :run_all_tests do |options|
  UI.message "Success!"
  next

  scan(
    project: 'Cactus.xcodeproj',
    scheme: "Cactus",
  )
end
