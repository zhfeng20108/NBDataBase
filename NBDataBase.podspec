Pod::Spec.new do |s|

  s.name         = "NBDataBase"
  s.version      = "0.2.3"
  s.summary      = "an orm database."

  s.description  = <<-DESC
                   orm database.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/zhfeng20108/NBDataBase"

  s.license      = "MIT"

  s.author             = { "zhfeng" => "hhzhangfeng2008@163.com" }

  s.platform     = :ios, "5.0"

  s.source       = { :git => "https://github.com/zhfeng20108/NBDataBase.git", :tag => "0.2.3" }

  s.source_files  = "NBDataBase/*.{h,m}"

  s.requires_arc = true
  s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SQLITE_HAS_CODEC=1 HAVE_USLEEP=1' }

  s.default_subspec = 'standard'

  # use the built-in library version of sqlite3
  s.subspec 'standard' do |ss|
    ss.dependency 'FMDB/SQLCipher'
    ss.library = 'sqlite3.0'
    ss.source_files = 'NBDataBase/*.{h,m}'
  end

  # use FMDB and WCDB
  s.subspec 'WCDB' do |ss|
    ss.dependency 'FMDB/Encrypt' #私有仓库
    ss.source_files = 'NBDataBase/*.{h,m}'
  end

end
