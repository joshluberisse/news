//
//  FirstViewController.swift
//  TheNews.tvos
//
//  Created by Daniel on 4/26/20.
//  Copyright © 2020 dk. All rights reserved.
//

import UIKit

class TvViewController: UIViewController {
    var category: NewsCategory = .general

    // UI
    private let tableView = UITableView()
    private let backgroundImageView = UIImageView()
    private let content = InsetLabel()
    private let qrImageView = UIImageView()

    // Date
    private var items: [Article] = []
    private let imageDownloader = ImageDownloader()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        setup()
        config()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData(category.rawValue)
    }
}

extension TvViewController: Configurable {
    func setup() {
        content.label.numberOfLines = 0
        content.backgroundColor = .lightGray
        content.alpha = 0
        content.addTvCornerRadius()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TvNewsCell.self, forCellReuseIdentifier: TvNewsCell.ReuseIdentifier)

        qrImageView.layer.cornerRadius = 6
        qrImageView.layer.masksToBounds = true
    }
    
    func config() {
        // Image
        backgroundImageView.frame = view.bounds
        view.addSubview(backgroundImageView)
        
        backgroundImageView.addGradientLeftRight()
        
        // Table
        view.addSubviewForAutoLayout(tableView)
        let tableWidth = view.bounds.size.width / 3
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            tableView.widthAnchor.constraint(equalToConstant: tableWidth),
        ])
        
        // Content, QR code
        view.addSubviewForAutoLayout(content)
        view.addSubviewForAutoLayout(qrImageView)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: 75),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            qrImageView.leadingAnchor.constraint(equalTo: content.trailingAnchor, constant: 40),

            qrImageView.heightAnchor.constraint(equalToConstant: 200),
            qrImageView.widthAnchor.constraint(equalToConstant: 200),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: qrImageView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: qrImageView.bottomAnchor),
        ])
    }
}

extension TvViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        let c = tableView.dequeueReusableCell(withIdentifier: TvNewsCell.ReuseIdentifier) as! TvNewsCell
        
        c.configure(item)
        
        imageDownloader.getImage(imageUrl: item.urlToSourceLogo, size: TvNewsCell.LogoSize) { (image) in
            c.configureLogo(image)
        }
        
        return c
    }
}

extension TvViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    // TODO: prevent issue of image updating when fast scrolling
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        context.previouslyFocusedView?.backgroundColor = .clear
        context.nextFocusedView?.backgroundColor = .colorForSameRgbValue(50)

        guard let indexPath = context.nextFocusedIndexPath else { return }

        let item = items[indexPath.row]
        update(item)
    }
}

private extension TvViewController {
    func loadData(_ category: String) {
        guard let url = URL.newsApiUrlForCategory(category) else {
            print("load data error")
            return
        }

        url.get(type: Headline.self) { [unowned self] (result) in
            switch result {
            case .success(let headline):
                self.items = headline.articles
                self.tableView.reloadData()

                guard let item = headline.articles.first else { return }

                self.updateImage(url: item.urlToImage)

            case .failure(let e):
                print(e.localizedDescription)
            }
        }
    }

    func update(_ item: Article) {
        updateImage(url: item.urlToImage)

        content.alpha = 0.6
        content.label.text = item.descriptionOrContent

        guard let ciImage = item.url?.qrImage else { return }

        let image = UIImage.init(ciImage: ciImage)
        qrImageView.image = image
    }

    func updateImage(url: String?) {
        imageDownloader.getImage(imageUrl: url, size: view.bounds.size) { [unowned self] (image) in
            self.backgroundImageView.image = image
        }
    }
}
