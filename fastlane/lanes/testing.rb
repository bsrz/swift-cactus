lane :run_all_tests do |options|
  scan(
    project: 'Cactus.xcodeproj',
    scheme: "Cactus",
  )
end
