Pod::Spec.new do |s|
  s.name             = 'KKMultiLevelList'
  s.version          = '0.1.2'
  s.summary          = 'A multi-level expandable list manager built on IGListKit.'
  s.description      = <<-DESC
KKMultiLevelList flattens tree-structured business models into IGListKit sections.
It keeps UI fully owned by the host app while providing expansion, collapse,
batched child reveal, insertion, deletion, and footer state management.
  DESC

  s.homepage         = 'https://github.com/kriskicekk/KKMultiLevelList'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'kris cheng'
  s.source           = { :git => 'https://github.com/kriskicekk/KKMultiLevelList.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.requires_arc = true

  s.source_files = 'Sources/KKMultiLevelList/**/*.{h,m}'
  s.public_header_files = 'Sources/KKMultiLevelList/*.h'

  s.dependency 'IGListKit', '~> 5.2.0'
end
