//
//  FeedPostPollCell.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 16/8/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

protocol FeedPostPollCellDelegate: AnyObject {
    func feedPostPollCellDidTapVotePoll(model: PollFeedModel, answerIds: [String])
    func feedPostPollCellDidTapClosePoll(model: PollFeedModel)
}

class FeedPostPollCell: UITableViewCell {
    weak var delegate: FeedPostPollCellDelegate?
    var pollFeedModel: PollFeedModel?
    
    private var selectedAnswerIds: [String] = []
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var totalVoteLabel: UILabel!
    @IBOutlet weak var totalOfAnswerLabel: UILabel!
    @IBOutlet weak var multipleVoteLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var voteStatusLabel: UILabel!
    @IBOutlet weak var answerTableView: UITableView!
    @IBOutlet weak var answerHeightTableView: NSLayoutConstraint!
    @IBOutlet weak var submitPollButton: UIButton!
    @IBOutlet weak var closedPollButton: UIButton!
    @IBOutlet weak var closedPollInLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        answerTableView.register(UINib(nibName: "FeedPostPollAnswerTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedPostPollAnswerTableViewCell")
        answerTableView.delegate = self
        answerTableView.dataSource = self
        answerTableView.tableFooterView = UIView()
        submitPollButton.isEnabled = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = "Question: "
        totalVoteLabel.text = "Total vote: "
        multipleVoteLabel.text = "isMultipleVoted: "
        statusLabel.text = "Status: "
        closedPollInLabel.text = "Closed in: "
        totalOfAnswerLabel.text = "Total options: "
        voteStatusLabel.text = "isVote: "
        selectedAnswerIds = []
    }
    
    func display(model: PollFeedModel) {
        pollFeedModel = model
        titleLabel.text = "Question: " + model.text
        totalVoteLabel.text = "Total vote: \(model.voteCount)"
        multipleVoteLabel.text = "isMultipleVoted: \(model.isMultipleVoted)"
        statusLabel.text = "Status: \(model.status)"
        let day = model.closedIn/1000/60/60/24
        closedPollInLabel.text = "Closed in: \(day)"
        totalOfAnswerLabel.text = "Total options: \(model.answers.count)"
        voteStatusLabel.text = "isVote: \(model.isVoted)"
        submitPollButton.isEnabled = !model.isVoted
        closedPollButton.isEnabled = !model.isClosed
        answerHeightTableView.constant = CGFloat(58 * model.answers.count)
        answerTableView.reloadData()
    }
    
    // MARK: - Action
    @IBAction func onTapVotePoll() {
        guard let poll = pollFeedModel else { return }
        delegate?.feedPostPollCellDidTapVotePoll(model: poll, answerIds: selectedAnswerIds)
    }
    
    @IBAction func onTapClosePoll()  {
        guard let poll = pollFeedModel else { return }
        delegate?.feedPostPollCellDidTapClosePoll(model: poll)
    }
}

extension FeedPostPollCell: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let poll = pollFeedModel, !poll.isClosed, !poll.isVoted else { return }
        let answer = poll.answers[indexPath.row]
        if !poll.isMultipleVoted, selectedAnswerIds.count > 0 {
            if selectedAnswerIds.first == answer.id {
                selectedAnswerIds.removeAll()
                selectedAnswer(poll: poll, answer: answer, tableView: tableView)
            }
            return
        }
        selectedAnswer(poll: poll, answer: answer, tableView: tableView)
    }
    
    private func selectedAnswer(poll: PollFeedModel, answer: PollFeedModel.PollFeedAnswerModel, tableView: UITableView)  {
        answer.isSelected = !answer.isSelected
        if answer.isSelected {
            selectedAnswerIds.append(answer.id)
        } else {
            if let index = selectedAnswerIds.firstIndex(of: answer.id) {
                selectedAnswerIds.remove(at: index)
            }
        }
        submitPollButton.isEnabled = poll.answers.contains(where: { $0.isSelected })
        tableView.reloadData()
    }
    
}

extension FeedPostPollCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pollFeedModel?.answers.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedPostPollAnswerTableViewCell", for: indexPath)
        configure(cell, at: indexPath)
        return cell
    }
    
    private func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? FeedPostPollAnswerTableViewCell, let answers = pollFeedModel?.answers {
            cell.display(model: answers[indexPath.row])
        }
    }
}
