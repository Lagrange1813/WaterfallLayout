//
//  ViewController.swift
//  CompositionalLayoutWithWaterfall
//
//  Created by Lagrange1813 on 2022/8/13.
//

import SnapKit
import UIKit

class ViewController: UIViewController {
  var collectionView: UICollectionView?
  var dataSource: UICollectionViewDiffableDataSource<Section, TestItem>?
  
  weak var waterfallLayoutDelegate: WaterfallLayoutDelegate?
  
  enum Section: CaseIterable {
    case main
  }
  
  var testModel: [TestItem] = {
    var result: [TestItem] = []
    for i in 0 ... 70 {
      result.append(TestItem(name: "Test \(i)"))
    }
    return result
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    waterfallLayoutDelegate = self
    
    configureCollectionView()
    configureDataSource()
    setupSnapshot()
    
    let topContrast = UIView()
    topContrast.backgroundColor = .systemGray
    view.addSubview(topContrast)
    topContrast.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
    }
    
    let bottomContrast = UIView()
    bottomContrast.backgroundColor = .systemGray
    view.addSubview(bottomContrast)
    bottomContrast.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalToSuperview()
    }
  }
}

extension ViewController {
  func configureCollectionView() {
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateCollectionViewLayout())
    
    guard let collectionView else { return }
    
    collectionView.backgroundColor = .systemBackground
    collectionView.register(TestCell.self, forCellWithReuseIdentifier: TestCell.identifier)
    
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints { make in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
  
  func configureDataSource() {
    guard let collectionView else { return }
    dataSource = UICollectionViewDiffableDataSource<Section, TestItem>(collectionView: collectionView) {
      (collectionView: UICollectionView, indexPath: IndexPath, _: TestItem) -> UICollectionViewCell? in
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TestCell.identifier, for: indexPath)
      cell.backgroundColor = .systemPink
      return cell
    }
  }
  
  func setupSnapshot() {
    guard let dataSource else { return }
    var snapshot = NSDiffableDataSourceSnapshot<Section, TestItem>()
    snapshot.appendSections([Section.main])
    snapshot.appendItems(testModel)
    dataSource.apply(snapshot)
  }
  
  func generateCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    let layout = UICollectionViewCompositionalLayout {
      [unowned self] (sectionIndex: Int, _: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
      let sectionLayoutKind = Section.allCases[sectionIndex]
      switch sectionLayoutKind {
      case .main: return generateWaterfallSection(in: sectionIndex)
      }
    }
    return layout
  }
    
  func generateWaterfallSection(in section: Int) -> NSCollectionLayoutSection? {
    guard let collectionView else { return nil }
    
    let edgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
      
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(100)
    )
    let group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) {
      [unowned self] environment -> [NSCollectionLayoutGroupCustomItem] in
        
      var items: [NSCollectionLayoutGroupCustomItem] = []
      
      let space: CGFloat = self.waterfallLayoutDelegate.flatMap { CGFloat($0.columnSpace()) } ?? 1.0
      let numberOfColumn = self.waterfallLayoutDelegate?.numberOfColumns() ?? 2
      
      var layouts: [Int: CGFloat] = {
        var result: [Int: CGFloat] = [:]
        for x in 0 ..< numberOfColumn {
          result[x] = 0
        }
        return result
      }()
      
      let defaultSize = CGSize(width: 100, height: 100)
      
      var targetColumn = 0
      
      (0 ..< collectionView.numberOfItems(inSection: section)).forEach {
        targetColumn = 0
        
        for x in 0 ..< numberOfColumn {
          if (layouts[x] ?? 0) < (layouts[targetColumn] ?? 0) {
            targetColumn = x
          }
        }
        
        let indexPath = IndexPath(item: $0, section: section)
          
        let size = self.waterfallLayoutDelegate?.columnsSize(at: indexPath) ?? defaultSize
        let aspect = CGFloat(size.height) / CGFloat(size.width)
          
        let width = (environment.container.effectiveContentSize.width - CGFloat(numberOfColumn - 1) * space) / CGFloat(numberOfColumn)
        let height = width * aspect
          
        let x = edgeInsets.leading + width * CGFloat(targetColumn) + space * CGFloat(targetColumn)
        let y = layouts[targetColumn] ?? 0.0
        
        let spacing = y == edgeInsets.top ? 0 : space
          
        let frame = CGRect(x: x, y: y + spacing, width: width, height: height)
        let item = NSCollectionLayoutGroupCustomItem(frame: frame)
        items.append(item)
          
        layouts[targetColumn] = y + spacing + height
      }
      return items
    }
        
    group.contentInsets = edgeInsets
      
    return NSCollectionLayoutSection(group: group)
  }
}

extension ViewController: WaterfallLayoutDelegate {
  func numberOfColumns() -> Int {
    2
  }
  
  func columnsSize(at indexPath: IndexPath) -> CGSize {
    let width = 100
    let height = Int.random(in: 10 ... 300)
    return CGSize(width: width, height: height)
  }
  
  func columnSpace() -> CGFloat {
    10.0
  }
}

class TestCell: UICollectionViewCell {
  static let identifier = "test"
}

struct TestItem: Hashable {
  let name: String
}

protocol WaterfallLayoutDelegate: AnyObject {
  func numberOfColumns() -> Int
  func columnsSize(at indexPath: IndexPath) -> CGSize
  func columnSpace() -> CGFloat
}
